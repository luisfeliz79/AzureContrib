FROM openjdk:17
COPY demoapp/target/demoapp-1.0.jar /tmp
COPY deploy/docker/runme.sh /tmp/runme.sh
COPY applicationinsights-agent-3.4.12.jar /tmp
COPY applicationinsights.json /tmp
RUN mkdir /tmp/data
RUN mkdir /tmp/tmp
COPY data/* /tmp/data
RUN chmod +x /tmp/runme.sh
WORKDIR /tmp
CMD ["/tmp/runme.sh"]