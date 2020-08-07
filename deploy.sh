#!/bin/bash
set -e

# Get Virtualenv Directory Path
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -z "$VIRTUAL_ENV_DIR" ]; then
    VIRTUAL_ENV_DIR="$SCRIPT_DIR/venv"
fi

echo "Using virtualenv located in : $VIRTUAL_ENV_DIR"

# If zip artefact already exists, back it up
if [ -f $SCRIPT_DIR/lambda_common_layer.zip ]; then
    mv $SCRIPT_DIR/lambda_common_layer.zip $SCRIPT_DIR/lambda_common_layer.zip.backup
fi

# Add virtualenv libs in new zip file
cd $VIRTUAL_ENV_DIR/lib/python3.8/site-packages
zip -r9 $SCRIPT_DIR/lambda_common_layer.zip *
cd $SCRIPT_DIR

# Add python code in zip file
zip -r9 $SCRIPT_DIR/lambda_common_layer.zip *.py

# Creating Layers
#chmod +x build_layer.sh
#./build_layer.sh
#chmod +x lambda/layers/numpy/build_layer.sh
#./lambda/layers/numpy/build_layer.sh
#chmod +x lambda/layers/pytz/build_layer.sh
#./lambda/layers/pytz/build_layer.sh

# Run terraform apply
terraform apply