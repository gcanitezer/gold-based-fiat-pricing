#!/bin/bash

export PKG_DIR="lambda/layers/pytz/python"

rm -rf ${PKG_DIR} && mkdir -p ${PKG_DIR}

docker run --rm -v $(pwd):/foo -w /foo lambci/lambda:build-python3.8 \
    pip3 install -r lambda/layers/pytz/requirements.txt --no-deps -t ${PKG_DIR}

zip -r lambda/layers/pytz/pytz_layer.zip lambda/layers/pytz/python