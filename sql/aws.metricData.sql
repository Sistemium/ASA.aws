create or replace function aws.metricDataMemberDimension (
    @name STRING,
    @value int,
    @n int default 1,
    @memberN int default 1,
) returns text
begin

    return string(
        '&MetricData.member.', @memberN, '.Dimensions.member.', @n, '.Name=', @name,
        '&MetricData.member.', @memberN, '.Dimensions.member.', @n, '.Value=', @value
    ;
    
end;


create or replace function aws.metricDataMember (
    @name STRING,
    @unit varchar(16) default 'Count',
    @value int,
    @ts timestamp default now (),
    @n int default 1,
    @extraDimensions text default null
) returns text
begin

    return string(
        '&MetricData.member.', @n, '.MetricName=', @name,
        '&MetricData.member.', @n, '.Unit=', @unit,
        '&MetricData.member.', @n, '.Value=', @value,
        '&MetricData.member.', @n, '.Timestamp=', util.tzTimestamp(util.utc(@ts)),
        aws.metricDataMemberDimension ('Server', property('servername'), 1, @n),
        aws.metricDataMemberDimension ('Database', current database, 2, @n),
        @extraDimensions
    );
    
end;


create or replace function aws.putMetricData (
    @data text,
    @ns varchar(32) default 'ASA Metrics'
) returns GUID
begin

    declare @result GUID;
    declare @xml XML;
    
    set @xml = aws.httpPost (
        'http://monitoring.eu-west-1.amazonaws.com',
        aws.signedQuery (
            util.getUserOption('AWSAccessKeyId'),
            util.getUserOption('AWSSecret'),
            aws.queryData ('PutMetricData', 'Namespace=' + @ns + @data)
        )
    );

    select RequestId into @result
    from openxml(@xml,'/*/*') with (
        RequestId GUID '*:RequestId'
    );
    
    return @result;
    
end;


create or replace function aws.putMetricDatum (
    @name STRING,
    @value int,
    @ts timestamp default now(),
    @unit varchar(16) default 'Count',
    @ns varchar(32) default 'ASA Metrics'
) returns GUID
begin

    return aws.putMetricData (
        @ns, aws.metricDataMember (@name, @unit, @value, @ts) 
    );
    
end;