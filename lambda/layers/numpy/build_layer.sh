#!/bin/bash

export PKG_DIR="lambda/layers/numpy/python"

rm -rf ${PKG_DIR} && mkdir -p ${PKG_DIR}

docker run --rm -v $(pwd):/foo -w /foo lambci/lambda:build-python3.8 \
    pip3 install -r lambda/layers/numpy/requirements.txt --no-deps -t ${PKG_DIR}

zip -r lambda/layers/numpy/numpy_layer.zip lambda/layers/numpy/python