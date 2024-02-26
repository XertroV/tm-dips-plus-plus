#!/usr/bin/env bash

./process_titles.py
# cp titles_normal.psv ../../src/Collections/
cp -v ./*.psv ../../src/Collections/
