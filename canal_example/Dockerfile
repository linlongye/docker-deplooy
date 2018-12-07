FROM openjdk:8-jdk-alpine
COPY canal.sample-1.0-SNAPSHOT-jar-with-dependencies.jar /root/db/app.jar
COPY ../wait_for.sh /wait_for.sh
WORKDIR /root/db
ENTRYPOINT [ "java","-jar","app.jar" ]