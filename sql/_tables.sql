grant connect to uac;
grant dba to uac;

create table uac.account(

    id integer not null,
    name varchar(512) not null,
    email varchar(512) not null,
    code varchar(512) not null,
    
    domainId varchar(512) not null,
    
    unique (domainId),

    xid GUID, ts TS, cts CTS,
    unique (xid), primary key (id)
);

comment on table uac.account is 'UOAuth cached account info'
;