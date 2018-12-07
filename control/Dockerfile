FROM openjdk:8-jdk-alpine
COPY controlservice-0.0.1-SNAPSHOT.jar /root/db/app.jar
COPY ../wait_for.sh /wait_for.sh
# COPY application.properties /root/db/application.properties
WORKDIR /root/db
EXPOSE 8081/tcp
ENTRYPOINT [ "java","-jar","app.jar" ]