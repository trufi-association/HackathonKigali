#!/bin/sh

file_name="otp-1.5.0-shaded.jar"
[ -z "${JAVA_MAX_MEMORY}" ] && JAVA_MAX_MEMORY="-Xmx2G"

if ! [ -f "./data/Graph.obj" ]; then
    echo "Build Graph"
    java $JAVA_MAX_MEMORY -jar $file_name --build ./data --preFlight
else
    echo "Load Graph"
    java $JAVA_MAX_MEMORY -jar $file_name --autoScan --graphs ./data --inMemory
fi