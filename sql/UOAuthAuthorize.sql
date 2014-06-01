create or replace function uac.UOAuthAuthorize(
    @code STRING
) returns xml
begin
    declare @roles xml;
    declare @id ID;
    
    select roles
        into @roles
        from uac.token
    where token = @code
        and expireTs > now()
    ;
    
    if isnull(@code,'') = '' then
        set @roles = xmlelement('error', 'Token required');
        return @roles;
    end if;
    
    if @roles is null then
        
        if isnull(util.getUserOption('uac.emailAuth'),'0') = '0' then    
            set @roles = util.unactGet(
                util.getUserOption('uoauthurl')
                + '/roles?access_token='+@code
            );
        else
            set @roles = eac.authorize(@code);
        end if;
            
        if exists(
            select * from openxml(@roles,'/*:response/*:roles/*:role') with(
                code long varchar '*:code'
            ) where code = 'authenticated'
        ) then
            
            message 'uac.UOAuthAuthorize @code=', @code
                DEBUG ONLY
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
                (select id
                    from openxml(@roles, '/*:response/*:account')
                        with(id long varchar '*:id')
                ) as account
            ;
                
            set @id = (select id from uac.token where token = @code);
            
            insert into uac.tokenRole with auto name select
                @id as token, code, data
            from openxml(@roles, '/*:response/*:roles/*:role') with(
                code long varchar '*:code', data long varchar '*:data'
            );
            
            insert into uac.account on existing update with auto name
            select
                id,
                isnull(name, username) as name,
                email,
                isnull(code,email) as code
            from openxml(@roles, '/*:response/*:account')
                with(
                     id long varchar '*:id',
                     name long varchar '*:name',
                     username long varchar '*:username',
                     email long varchar '*:email',
                     code long varchar '*:code'
                )
            ;
            
        end if;
        
    end if;
    
    return @roles;

end;