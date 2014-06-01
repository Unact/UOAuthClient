create or replace function uac.tokenDomainURL (
    @tokenDomain STRING
) returns STRING
begin

    return coalesce (
        util.getUserOption('uoauth.'+@tokenDomain+'.url'),
        util.getUserOption('uoauthurl')
    );
    
end;