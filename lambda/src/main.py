import json
import pandas as pd

def handle(event, context):
    EmptyDF = pd.DataFrame({'A' : []})
    return EmptyDF.to_string()