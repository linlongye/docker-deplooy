FROM openjdk:8u181-jdk-slim-stretch
COPY ./apache-flume-1.8.0-bin/ /root/flume/
RUN ls -la /root/flume \
    && cd /root/flume/bin \
    && chmod +x flume-ng
WORKDIR /root/flume/bin
EXPOSE 20001
ENTRYPOINT  ["./flume-ng" , "agent", "-c", "../conf", "-f", "../conf/mqandmysql.conf", "-n", "agent1" ,"-Dflume.root.logger=INFO,console" ]