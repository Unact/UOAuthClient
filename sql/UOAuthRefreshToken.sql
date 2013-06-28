create or replace function uac.UOAuthRefreshToken(
    @refreshToken long varchar,
    @clientId long varchar,
    @clientSecret long varchar
)
returns xml
begin
    declare @result xml;

    set @result = util.unactGet(util.getUserOption('uoauthurl')
                                   + '/token?refresh_token=' + @refreshToken
                                   + '&client_id=' + @clientId
                                   + '&client_secret=' + @clientSecret);   
    
    return @result;
end
;