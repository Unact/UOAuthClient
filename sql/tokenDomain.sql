create or replace function uac.tokenDomain (
    @token STRING
) returns STRING
begin

    return isnull(regexp_substr (@token, '(?<=@).*'), 'uoauth');
    
end;