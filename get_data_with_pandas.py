import pandas as pd
from pandas_datareader import data
import boto3
import botocore
import json

# Define the instruments to download. We would like to see Apple, Microsoft and the S&P500 index.
tickers = ['AAPL', 'MSFT', '^GSPC']

# We would like all available data from 01/01/2000 until 12/31/2016.
start_date = '2020-07-10'
end_date = '2020-07-17'


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
    # User pandas_reader.data.DataReader to load the desired data. As simple as that.
    panel_data = data.DataReader('GC=F', 'yahoo', start_date, end_date)

    # Getting just the adjusted closing prices. This will return a Pandas DataFrame
    # The index in this DataFrame is the major index of the panel_data.
    close = panel_data['Close']

    gold = pd.Series( panel_data.eval(' 31.1 / Close '))

    # Getting all weekdays between 01/01/2000 and 12/31/2016
    all_weekdays = pd.date_range(start=start_date, end=end_date, freq='B')
    all_friday = pd.date_range(start=start_date, end=end_date, freq='W-FRI')
    # How do we align the existing prices in adj_close with our new set of dates?
    # All we need to do is reindex close using all_weekdays as the new index
    gold = gold.reindex(all_weekdays)
    close = close.reindex(all_friday)

    # Reindexing will insert missing values (NaN) for the dates that were not present
    # in the original set. To cope with this, we can fill the missing by replacing them
    # with the latest available price for each instrument.
    gold = gold.fillna(method='ffill')
    close = close.fillna(method='ffill')
    print(gold)
    print(close)

    # Get Bucket Name
    bucket = event['bucket']

    # Get File Path
    key = event['file_path']

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
    print(file);

    result = s3.Object(bucket, key).put(Body=(bytes( gold.to_json(orient='split').encode('UTF-8'))),
                                        ContentType='application/json')
    # result = s3.Object(bucket, key).put(Body=gold.to_json())
    print(result)
    print(gold.to_json())

    obj = s3.Object(bucket, key).get()['Body'].read().decode('UTF-8')

    new_gold = pd.read_json(obj, orient='split', typ='series')
    print(new_gold)
    # new_gold = pd.Series( )

    # print(json.loads( new_gold))

if __name__ == "__main__":
    # Test data
    test = {"bucket": "goldstat-stocks", "file_path": "USD"}
    # Test function
    lambda_handler(test, None)
