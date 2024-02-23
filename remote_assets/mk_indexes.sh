#!/usr/bin/env bash

cd audio
find | grep -E '.{1,}\..{1,}' | sed 's|^\./||' | sort | tee index.txt
cd ..
