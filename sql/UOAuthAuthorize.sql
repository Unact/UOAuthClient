create or replace function uac.UOAuthAuthorize(
    @code STRING
) returns xml
begin
    declare @result xml;
    declare @id ID;
    
    select roles
        into @result
        from uac.token
    where token = @code
        and expireTs > now()
    ;
    
    if isnull(@code,'') = '' then
        set @result = xmlelement('error', 'Token required');
        return @result;
    end if;
    
    if @result is null then
    
    
        if isnull(util.getUserOption('uac.emailAuth'),'0') = '0' then    
            set @result = util.unactGet(
                util.getUserOption('uoauthurl')
                + '/roles?access_token='+@code
            );
        else
            set @result = eac.authorize(@code);
        end if;
            
        if exists(
            select * from openxml(@result,'/*:response/*:roles/*:role') with(
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
                @result as roles,
                (select dateadd(second, isnull(expiresIn, 3600), now())
                    from openxml(@result,'/*:response/*:token')
                        with(ts datetime '*:ts', expiresIn integer '*:expiresIn')
                ) as expireTs,
                (select id
                    from openxml(@result, '/*:response/*:account')
                        with(id long varchar '*:id')
                ) as account
            ;
                
            set @id = (select id from uac.token where token = @code);
            
            insert into uac.tokenRole with auto name select
                @id as token, code, data
            from openxml(@result, '/*:response/*:roles/*:role') with(
                code long varchar '*:code', data long varchar '*:data'
            );
            
            insert into uac.account on existing update with auto name       
            select
                id,
                isnull(name, username) as name,
                email,
                isnull(code,email) as code
            from openxml(@result, '/*:response/*:account')
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
    
    return @result;

end;