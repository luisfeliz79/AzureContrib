#!/bin/bash

echo "Executing JVM with Application Insights Agent"
cd /tmp
java -javaagent:applicationinsights-agent-3.4.12.jar -jar demoapp-1.0.jar

