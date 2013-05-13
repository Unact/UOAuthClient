create or replace function uac.account(
    @token long varchar,
    @property long varchar default 'id'
) returns STRING
begin

    declare @result STRING;
    
    set @result = (
        select list(data)
        from openxml(
            uac.UOAuthAuthorize(@token)
            ,'/*:response/*:account/*:'+@property
        ) with ( data STRING '.' )
    );

    return @result;
    
end;