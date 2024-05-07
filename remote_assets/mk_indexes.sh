#!/usr/bin/env bash

(cd audio &&
find | grep -E '.{1,}\..{1,}' | grep -v "Zone.Identifier" | grep -v " - Copy" | grep -v ".ogg$" | sed 's|^\./||' | sort | tee index.txt)
(cd vid && ls *.webm) | tee vid/clip-links.txt
