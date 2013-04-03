create global temporary table if not exists uac.token(
    token long varchar unique,
    expireTs datetime,
    roles xml,
    
    account integer,

    id ID, xid GUID, ts TS, cts CTS,
    unique (xid), primary key (id)
    
)  not transactional share by all
;