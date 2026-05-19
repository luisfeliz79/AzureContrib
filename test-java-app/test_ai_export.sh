export APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=d428d525-c3eb-476f-b836-9daf116f7381;IngestionEndpoint=https://eastus2-0.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus2.livediagnostics.monitor.azure.com/;ApplicationId=62febc61-fd6f-4633-b9bd-3d1967df5690"

java -javaagent:applicationinsights-agent-3.7.4.jar -jar ./demoapp-1.0.jar
