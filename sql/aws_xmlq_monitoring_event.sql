sa_make_object 'event', 'aws_xmlq_monitoring';

drop event aws_xmlq_monitoring;

create event aws_xmlq_monitoring
handler begin

    declare @tsB TS;
    declare @tsE TS;
    
    if EVENT_PARAMETER('NumActive') <> '1' then 
        return;
    end if;
 
    set @tsE = now();
    set @tsB = dateadd(minute, -1, @tsE);
    
    for c as c cursor for
        
        select
            count(*) as [XMLQ Requests Count],
            sum(datediff(ms, cts, ts)) as [XMLQ Requests Length],
            @tsE as [Timestamp],
            aws.putMetricDatum (
                'XMLQ Requests',
                [XMLQ Requests Count],
                [Timestamp]
                ,'Count'
            ) as [putCountResponse],
            aws.putMetricDatum (
                'XMLQ Requests',
                [XMLQ Requests Length],
                [Timestamp],
                'Milliseconds'
            ) as [putCountResponse],
        from xmlgate.query
        where cts >= @tsB and cts < @tsE
        
    do message
        
        current database, '.aws_xmlq_monitoring',
        ' put: ', [XMLQ Requests],
        ' for ts: ''', [Timestamp], '''',
        ' putCountResponse: ', [putCountResponse]
        
    debug only end for;
    
end;

alter event aws_xmlq_monitoring add SCHEDULE heartbeat
    start time '00:00:01'
    every 1 minutes
;
