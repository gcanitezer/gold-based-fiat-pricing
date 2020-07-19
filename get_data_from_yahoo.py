import csv
from botocore.vendored import requests


url = 'https://query1.finance.yahoo.com/v7/finance/download/GC=F?period1=951696000&period2=1595116800&interval=1d&events=history'


def lambda_handler(event, context):

    session = requests.Session()
    raw_data = session.get(url)

    decode_content = raw_data.content.decode('utf-8')

    reader = csv.reader(decode_content.splitlines(), delimiter=',')

    rows = list(reader)

    for row in rows:
        print(row)

    # TODO implement
    return {
        'statusCode': 200
    }


if __name__ == "__main__":

    # Test data
    test = {"bucket": "my_bucket", "file_path": "path_to_file"}
    # Test function
    lambda_handler(test, None)
