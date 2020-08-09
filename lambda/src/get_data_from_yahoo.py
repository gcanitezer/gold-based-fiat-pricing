import csv
import requests

url = 'https://query1.finance.yahoo.com/v7/finance/download/GC=F?period1=951696000&period2=1595116800&interval=1d&events=history'

def lambda_handler(event, context):

    raw_data = requests.get(url)
    
    decode_content = raw_data.content.decode('utf-8')

    reader = csv.reader(decode_content.splitlines(), delimiter=',')

    rows = list(reader)

    for row in rows:
        print(row)
        
    # TODO implement
    return {
        'statusCode': 200
    }
