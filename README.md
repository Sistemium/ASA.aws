ASA.aws
===========

SQL Anywhere implementation of AWS API

Depends on UDUtils

### Functions

aws.putMetricData (
    @name STRING,
    @value int,
    @ts timestamp default current utc timestamp,
    @unit varchar(16) default 'Count',
    @ns varchar(32) default 'ASA Metrics'
) returns GUID
