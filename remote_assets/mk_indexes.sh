#!/usr/bin/env bash

cd audio
find | grep -E '.{1,}\..{1,}' | grep -v "Zone.Identifier" | grep -v ".ogg$" | sed 's|^\./||' | sort | tee index.txt
cd ..
