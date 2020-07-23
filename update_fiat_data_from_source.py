import pandas as pd
from pandas_datareader import data
import boto3
import botocore
from datetime import datetime


# We would like all available data from 01/01/2000 until 12/31/2016.
start_date = '2000-01-01'
end_date = datetime.today().strftime('%Y-%m-%d')


# Checks if the file exists
def check_file(bucket, key):
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
    stock = event['stock']
    # Get Bucket Name
    bucket = event['bucket']

    # Get File Path
    key = event['file_path']

    s3 = boto3.resource('s3')
    goldFile = 'USD'

    #read Gold data to multiply it with the fiat currency in XXXUSD format data.
    s3obj = s3.Object(bucket, goldFile).get()['Body'].read().decode('UTF-8')
    gold = pd.read_json(s3obj, orient='split', typ='series')

    # User pandas_reader.data.DataReader to load the desired data. As simple as that.
    stock_data = data.DataReader(stock, 'yahoo', start_date, end_date)

    # Getting just the adjusted closing prices. This will return a Pandas DataFrame
    # The index in this DataFrame is the major index of the panel_data.
    stock_close = pd.Series(stock_data['Close'])
    all_weekdays = pd.date_range(start=start_date, end=end_date, freq='B')
    stock_close = stock_close.reindex(all_weekdays).fillna(method='ffill')


    stock_gold = gold * stock_close
    # gold = pd.Series( panel_data.eval(' 31.1 / Close '))

    print(stock_gold)



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
    print(file_exists)

    result = s3.Object(bucket, key).put(Body=(bytes(stock_gold.to_json(orient='split').encode('UTF-8'))),
                                        ContentType='application/json')
    # result = s3.Object(bucket, key).put(Body=gold.to_json())
    print(result)
    print(stock_gold.to_json())

    obj = s3.Object(bucket, key).get()['Body'].read().decode('UTF-8')

    new_gold = pd.read_json(obj, orient='split', typ='series')
    print(new_gold)
    # new_gold = pd.Series( )

    # print(json.loads( new_gold))

if __name__ == "__main__":
    # Test data
    test = {'stock':'GBPUSD=X', "bucket": "goldstat-stocks", "file_path": "GBP"}
    # Test function
    lambda_handler(test, None)
