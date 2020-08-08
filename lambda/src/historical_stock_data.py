#!python

import pandas as pd
from pandas_datareader import data
import boto3
import botocore
import json

# Checks if the file exists
def check_file(bucket, key):

    s3 = boto3.resource('s3')
    file_exists = False
    try:
        s3.Object(bucket, key).load()
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "404":
            file_exists = False
        else:
            raise
    else:
        file_exists = True
    return file_exists


def lambda_handler(event, context):
    # We would like all available data from 01/01/2000 until 12/31/2016.

    print(event)

    bucket = 'goldstat-stocks'
    key = event['stock']
    start_date = event['startdate']
    end_date = event['enddate']

    print([key, start_date, end_date])

    s3 = boto3.resource('s3')
    try:
        file = s3.Object(bucket, key).load()
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "404":
            file_exists = False
        else:
            raise
    else:
        file_exists = True

    obj = s3.Object(bucket, key).get()['Body'].read().decode('UTF-8')

    gold = pd.read_json(obj, orient='split', typ='series')
    print(gold)

    # Getting all weekdays between 01/01/2000 and 12/31/2016
    all_weekdays = pd.date_range(start=start_date, end=end_date, freq='B')
    # all_friday = pd.date_range(start=start_date, end=end_date, freq='W-FRI')

    # How do we align the existing prices in adj_close with our new set of dates?
    # All we need to do is reindex close using all_weekdays as the new index
    gold = gold.reindex(all_weekdays)
    outjson = json.loads( gold.to_json(orient='split'))

    return outjson

    # new_gold = pd.Series( )

    # print(json.loads( new_gold))
