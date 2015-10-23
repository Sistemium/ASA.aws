grant connect to aws;
grant dba to aws;

call util.setuseroption('AWSAccessKeyId','');
call util.setuseroption('AWSSecret','');
commit;


create or replace function aws.httpPostProxy (
    url text,
    request text
)
RETURNS TEXT
    URL '!url'
    TYPE 'http:post:application/x-www-form-urlencoded'
;

create or replace function aws.httpPost (
    url text,
    request text
) RETURNS TEXT
begin

    declare @result text;

    set @result = aws.httpPostProxy (url, request);

    return @result;

exception WHEN OTHERS THEN

    return null;

end;


create or replace function aws.signedQuery (
    @AWSAccessKeyId varchar(128),
    @AWSSecret varchar(128),
    @query text,
    @uri varchar(128) default '/',
    @verb varchar(4) default 'POST',
    @host varchar(64) default 'monitoring.eu-west-1.amazonaws.com'
) returns text
begin

    declare @result text;

    declare @StringToSign text;

    set @StringToSign = string (
        @verb, '\n',
        @host, '\n',
        @uri, '\n',
        'AWSAccessKeyId=', @AWSAccessKeyId,
        '&', @query
    );

    return string (
        'AWSAccessKeyId=', @AWSAccessKeyId,
        '&', @query,
        '&Signature=', util.urlEncode(BASE64_ENCODE(util.hextobin(
            util.hmac (@AWSSecret,@StringToSign,regexp_substr(@query,'(?<=SignatureMethod=Hmac)[^&]*'))
        )))
    );

end;


create or replace function aws.queryData (
    @Action varchar(64) default 'ListMetrics',
    @params text default '',
    @SignatureMethod varchar(64) default 'HmacSHA256',
    @SignatureVersion int default 2,
    @Timestamp varchar(32) default current utc timestamp,
    @Version varchar(10) default '2010-08-01'
) returns text
begin

    declare @result text;

    set @result = string(
        'Action=', @Action,
        '&SignatureMethod=', @SignatureMethod,
        '&SignatureVersion=', @SignatureVersion,
        '&Timestamp=', util.tzTimestamp(@Timestamp),
        '&Version=', @Version,
        if @params <> '' then '&'+@params endif
    );

    set @result = (
        select list(string(var,'=',util.urlencode(val)),'&' order by var)
        from openstring (value @result)
        with (var text, val text)
        option ( DELIMITED BY '=' ROW DELIMITED BY '&')
        as vars
    );

    return @result;

end;
