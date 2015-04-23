create or replace function uac.UOAuthAuthorize(
    @code STRING,
    @domain STRING default uac.tokenDomain(@code)
) returns xml
begin
    declare @roles xml;
    declare @id ID;

    select roles
        into @roles
        from uac.token
    where token = @code
        and (expireTs > now() or expireTs is null)
    ;

    if isnull(@code,'') = '' then
        set @roles = xmlelement('error', 'Token required');
        return @roles;
    end if;

    if @roles is null then

        if isnull(util.getUserOption('uac.emailAuth'),'0') = '0' then
            begin
                declare @url STRING;
                set @url = uac.tokenDomainUrl (@domain);

                set @roles = uac.httpsGet(@url + '/roles?access_token=' + @code);
            end
        else
            set @roles = eac.authorize(@code);
        end if;

        if exists(
            select * from openxml(@roles,'/*:response/*:roles/*:role') with(
                code long varchar '*:code'
            ) where code = 'authenticated'
        ) then

            message 'uac.UOAuthAuthorize @code=', @code, ' @domain=', @domain
                DEBUG ONLY
            ;

            merge into uac.account
                using with auto name (
                    select
                        --id,
                        isnull(a.name, a.username) as name,
                        isnull(email, string (coalesce(a.username,a.id,a.code),'@',@domain)) as email,
                        isnull(a.code,a.email) as code,
                        string (
                            coalesce(a.id,a.code,a.username),
                            '@',
                            @domain
                        ) as domainId
                    from openxml(@roles, '/*:response/*:account')
                        with(
                            id long varchar '*:id',
                            name long varchar '*:name',
                            username long varchar '*:username',
                            email long varchar '*:email',
                            code long varchar '*:code'
                        ) as a
                ) as rolesAccount
                on rolesAccount.domainId = account.domainId
                when not matched then insert
                when matched then update
            ;

            insert into uac.token on existing update with auto name select
                (select id
                    from uac.token
                    where token = @code
                ) as id,
                @code as token,
                @roles as roles,
                (select dateadd(second, isnull(expiresIn, 3600), now())
                    from openxml(@roles,'/*:response/*:token')
                        with(ts datetime '*:ts', expiresIn integer '*:expiresIn')
                ) as expireTs,
                (select id from uac.account where domainId = (
                    select string (
                        coalesce(id,code,username),
                        '@',
                        @domain
                    ) from openxml(@roles, '/*:response/*:account')
                    with(
                        id long varchar '*:id',
                        name long varchar '*:name',
                        username long varchar '*:username',
                        email long varchar '*:email',
                        code long varchar '*:code'
                    )
                )) as account
            ;

            set @id = (select id from uac.token where token = @code);

            insert into uac.tokenRole with auto name select
                @id as token, code, data
            from openxml(@roles, '/*:response/*:roles/*:role') with(
                code long varchar '*:code', data long varchar '*:data'
            );


            call uac.triggerAuthEvents (@id);

        end if;

    end if;

    return @roles;

end;
