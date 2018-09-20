#!/bin/sh

# Remove Jekyll front matter
sed -e '1,5d' < course-overview.md > course-overview-slides.md

# Insert presentation title
sed -i '' '1i\
# CMPS290S: Languages and Abstractions for Distributed Programming' course-overview-slides.md

# Convert to remark.js slides
markdown-to-slides -d course-overview-slides.md -o course-overview-slides.html --level 5 --watch & open course-overview-slides.html

