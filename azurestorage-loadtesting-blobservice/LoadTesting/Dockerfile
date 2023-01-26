FROM openjdk:17
#COPY payloadTemplate/applicationinsights-agent-3.4.2.jar /tmp
#COPY payloadTemplate/applicationinsights.json /tmp

COPY javablob/target/dependency/* /tmp/
COPY javablob/target/javablob-1.0-SNAPSHOT.jar /tmp

COPY docker/runme.sh /tmp
COPY docker/config/* /tmp/
RUN chmod +x /tmp/runme.sh
RUN mkdir /tmp/workingTmp
WORKDIR /tmp
CMD ["./runme.sh"]
