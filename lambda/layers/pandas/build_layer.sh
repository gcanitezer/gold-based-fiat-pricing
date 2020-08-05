#!/bin/bash

export PKG_DIR="lambda/layers/pandas/python"

rm -rf ${PKG_DIR} && mkdir -p ${PKG_DIR}

docker run --rm -v $(pwd):/foo -w /foo lambci/lambda:build-python3.8 \
    pip3 install -r lambda/layers/pandas/requirements.txt --no-deps -t ${PKG_DIR}

zip -r lambda/layers/pandas/pandas_layer.zip lambda/layers/pandas/python