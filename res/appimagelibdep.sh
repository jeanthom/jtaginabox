#!/bin/bash

blacklist=$(wget https://raw.githubusercontent.com/probonopd/AppImages/master/excludelist -O - | sort | uniq | grep -v "^#.*" | grep "[^-\s]")
blacklist_regex=`echo $blacklist | tr " " "|" | sed 's/\./\\\\./g'`

if [ $# -lt 1 ]
then
    echo "Usage: $0 path/to/executable"
else
    ldd $1 | grep -o '\W/[^ ]*' | grep -vE $blacklist_regex | tr " " "\n"
fi

