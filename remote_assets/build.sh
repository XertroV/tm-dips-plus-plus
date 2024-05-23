#!/usr/bin/env bash

./upload-to-s3.sh
./mk_indexes.sh
./upload-to-s3.sh
