create or replace function uac.UOAuthAuthorize(@code long varchar)
returns xml
begin
    declare @result xml;
    
    select roles
      into @result
      from uac.token
     where token = @code
       and expireTs > now();
       
    if @result is null then
        set @result = util.unactGet(util.getUserOption('uoauthurl')
                                       + '/roles?access_token='+@code);
                                       
        if exists(select *
                    from openxml(@result,'/*:response/*:roles/*:role')
                         with(code long varchar '*:code')
                   where code = 'authenticated') then
                   
            insert into uac.token with auto name
            select @code as token,
                   @result as roles,
                   (select dateadd(second, expiresIn, ts)
                      from openxml(@result,'/*:response/*:token')
                           with(ts datetime '*:ts', expiresIn integer '*:expiresIn')) as expireTs,
                   (select id
                    from openxml(@result, '/*:response/*:account')
                   with(id long varchar '*:id')) as account;
                           
            insert into uac.account on existing update with auto name       
            select id,
                   name,
                   email,
                   code
              from openxml(@result, '/*:response/*:account')
                   with(
                        id long varchar '*:id',
                        name long varchar '*:name',
                        email long varchar '*:email',
                        code long varchar '*:code');

        end if;
        
    end if;
    
    return @result;

end
;