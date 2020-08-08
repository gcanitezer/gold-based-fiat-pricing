#!/bin/bash

export PKG_DIR="lambda/python"

rm -rf ${PKG_DIR} && mkdir -p ${PKG_DIR}

docker run --rm -v $(pwd):/foo -w /foo lambci/lambda:build-python3.8 \
    pip3 install -r lambda/requirements.txt --no-deps -t ${PKG_DIR}