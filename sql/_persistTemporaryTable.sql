drop table uac.token;

create table uac.token(

    token STRING unique,
    expireTs datetime,
    roles xml,

    account integer,

    id ID, xid GUID, ts TS, cts CTS,
    unique (xid), primary key (id)

)
;

drop table uac.tokenRole;

create table uac.tokenRole(

    code STRING,
    data STRING,

    not null foreign key(token) references uac.token on delete cascade,

    id ID, xid GUID, ts TS, cts CTS,
    unique (xid), primary key (id)

)
;
