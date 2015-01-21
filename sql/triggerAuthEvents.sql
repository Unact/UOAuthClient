create or replace procedure uac.triggerAuthEvents(
  @token IDREF
) begin

  declare @sql long varchar;

  for triggering as events cursor for
    select
      [event_name] as @event_name
    from sys.sysevent
    where [enabled] = 'Y'
      and [event_name] like 'UACAccountAuth%'
  do
    set @sql = string (
        'trigger event [', @event_name, '] ( ',
            '"token" = ''', @token, '''',
        ' )'
    );
    message 'uac.triggerAuthEvents: ', @sql to client;
    execute immediate @sql;
  end for;

end;
