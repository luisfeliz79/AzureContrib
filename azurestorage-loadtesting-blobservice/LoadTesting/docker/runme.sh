#!/bin/bash


## This script will start the java workload then quit and exit with code 0


#sed -i -e "s/--podname--/$HOSTNAME/g" applicationinsights.json
#java -cp "*" -javaagent:"applicationinsights-agent-3.4.2.jar" com.felizlabs.MultiThreadApp
java -cp "*" com.felizlabs.SingleThreadApp

exit 0
