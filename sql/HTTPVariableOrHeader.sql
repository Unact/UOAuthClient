create or replace function uac.HTTPVariableOrHeader (
    @name STRING default 'Authorization'
) returns STRING
begin

    return isnull(
        http_variable(@name+':'),
        regexp_substr(http_header(@name),'[^ ]*$')
    );
    
end;