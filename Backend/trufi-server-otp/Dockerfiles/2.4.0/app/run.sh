#!/bin/sh

file_name="otp-2.4.0-shaded.jar"
[ -z "${JAVA_MAX_MEMORY}" ] && JAVA_MAX_MEMORY='-Xmx2G'

if ! [ -f "./data/graph.obj" ]; then
    echo "Build Graph"
    java $JAVA_MAX_MEMORY -jar $file_name --build --save ./data --serve
else
    echo "Load Graph"
    java $JAVA_MAX_MEMORY -jar $file_name --load ./data --serve
fi

