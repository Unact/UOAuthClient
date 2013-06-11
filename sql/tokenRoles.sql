create or replace procedure uac.tokenRoles(
    @token long varchar default null
)
begin
    declare @roles xml;
    
    if varexists('@UOAuthAccessToken') <> 0 then
        set @token = @UOAuthAccessToken;
    end if;
    
    set @roles = uac.UOAuthAuthorize(@token);
    
    if not exists(select *
                    from openxml(@roles,'/*:response/*:roles/*:role')
                         with(code long varchar '*:code')
                   where code = 'authenticated') then
                   
        raiserror 55555 'Not authorized';
        return;    
    end if;

    select code,
           data
        from openxml(@roles,'/*:response/*:roles/*:role')
             with(code long varchar '*:code', data long varchar '*:data');

end
;