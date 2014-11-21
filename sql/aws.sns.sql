/*

select aws.publish (
    '{"APNS_SANDBOX":"{ \"aps\" : { \"alert\" : \"You have got email.\", \"badge\" : 9,\"sound\" :\"default\"}}"}',
    'arn:aws:sns:eu-west-1:554658909973:endpoint/APNS_SANDBOX/iSistemium/f473d72e-1d1d-368e-8397-64e41909340c'
)

*/


create or replace function aws.SNSPublish (
    @Message text,
    @TargetArn text
) returns GUID
begin

    declare @result GUID;
    declare @xml XML;

    set @xml = aws.httpPost (
        'http://sns.eu-west-1.amazonaws.com',
        aws.signedQuery (
            util.getUserOption('AWSAccessKeyId'),
            util.getUserOption('AWSSecret'),
            aws.queryData ('Publish', string(
                    'Message=',@Message,
                    '&TargetArn=',@TargetArn,
                    '&MessageStructure=json'
                ),
                'HmacSHA256', 2, current utc timestamp, '2010-03-31'
            ),
            '/','POST','sns.eu-west-1.amazonaws.com'
        )
    );

    select RequestId into @result
    from openxml(@xml,'/*/*') with (
        RequestId GUID '*:RequestId'
    ) where RequestId is not null;

    return @result;

end;

create or replace function aws.SNSCreatePlatformEndpoint (
    @PlatformApplicationArn text,
    @CustomUserData text,
    @Token text
) returns text
begin

    declare @result text;
    declare @xml XML;

    set @xml = aws.httpPost (
        'http://sns.eu-west-1.amazonaws.com',
        aws.signedQuery (
            util.getUserOption('AWSAccessKeyId'),
            util.getUserOption('AWSSecret'),
            aws.queryData ('CreatePlatformEndpoint', string(
                    'CustomUserData=',@CustomUserData,
                    '&PlatformApplicationArn=',@PlatformApplicationArn,
                    '&Token=',@Token
                ),
                'HmacSHA256', 2, current utc timestamp, '2010-03-31'
            ),
            '/','POST','sns.eu-west-1.amazonaws.com'
        )
    );

    select EndpointArn into @result
    from openxml(@xml,'/*/*') with (
        EndpointArn text '*:EndpointArn'
    ) where EndpointArn is not null;

    return @result;

end;
