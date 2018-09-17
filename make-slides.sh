#!/bin/sh

for file in README readings responses
do
    markdown-to-slides -d $file.md -o $file.html
    sed -i '' 's/\.md/.html/g' $file.html
done
open README.html
