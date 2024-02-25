#!/usr/bin/env bash

cd audio
find | grep -E '.{1,}\..{1,}' | grep -v "Zone.Identifier" | sed 's|^\./||' | sort | tee index.txt
cd ..
