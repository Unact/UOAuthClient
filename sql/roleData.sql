create or replace procedure uac.roleData(
    @token long varchar,
    @role long varchar
)
begin
    declare @roles xml;
    declare @roleData long varchar;
    
    set @roles = uac.UOAuthAuthorize(@token);
    
    if not exists(select *
                    from openxml(@roles,'/*:response/*:roles/*:role')
                         with(code long varchar '*:code')
                   where code = 'authenticated') then
                   
        raiserror 55555 'Not authorized';
        return;    
    end if;

    set @roleData = (select data
                       from openxml(@roles,'/*:response/*:roles/*:role')
                            with(code long varchar '*:code', data long varchar '*:data')
                      where code = @role);

    select [key],
           value
      from openstring(value isnull(@roleData,''))
           with([key] long varchar, value long varchar)
           option(delimited by '=' row delimited by '&') as t;

end
;