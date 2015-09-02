create or replace function uac.tokenHasRole (
    @role string,
    @UACToken STRING default util.HTTPVariableOrHeader ()
) returns BOOL begin

    declare @res BOOL;
    
    set @res = (
        select max(1) from uac.tokenRole tr
            join uac.token t on t.id = tr.token
        where t.token = @UACToken and tr.code = @role
    );
    
    return isnull(@res,0);

end;
