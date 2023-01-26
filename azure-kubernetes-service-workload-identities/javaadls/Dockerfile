FROM openjdk:17

COPY javaadls/target/dependency/* /tmp/
COPY javaadls/target/javaadls-1.0-SNAPSHOT.jar /tmp

COPY docker/runme.sh /tmp
COPY docker/config/* /tmp/
RUN chmod +x /tmp/runme.sh

WORKDIR /tmp
CMD ["./runme.sh"]
