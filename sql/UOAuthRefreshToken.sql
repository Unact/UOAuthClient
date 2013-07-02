create or replace function uac.UOAuthRefreshToken(
    @refreshToken long varchar,
    @clientId long varchar,
    @clientSecret long varchar
)
returns xml
begin
    declare @result xml;

    if exists(select *
                from sys.sysprocedure p join sys.sysuserperm u on p.creator = u.user_id
               where p.proc_name = 'token' 
                 and u.user_name = 'ua') then
                 
        set @result = ua.token(
                                @refreshToken,
                                null,
                                @clientId,
                                @clientSecret
                               );
                               
        set @result = xmlelement('response', @result);
                 
    else
        set @result = util.unactGet(util.getUserOption('uoauthurl')
                                       + '/token?refresh_token=' + @refreshToken
                                       + '&client_id=' + @clientId
                                       + '&client_secret=' + @clientSecret);
    end if;
    
    return @result;
end
;