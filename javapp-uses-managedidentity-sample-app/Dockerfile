FROM openjdk:17
COPY javamsidemo/target/javamsidemo-1.0-SNAPSHOT-jar-with-dependencies.jar /tmp
COPY runme.sh /tmp/runme.sh
RUN chmod +x /tmp/runme.sh
WORKDIR /tmp
CMD ["/tmp/runme.sh"]