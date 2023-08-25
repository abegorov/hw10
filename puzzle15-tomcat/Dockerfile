FROM alpine:3.18 AS builder
WORKDIR /build
RUN apk update && \
    apk add openjdk8 && \
    apk add maven && \
    apk add git && \
    git clone https://github.com/venkaDaria/puzzle15.git && \
    cd puzzle15 && \
    sed -i 's@</modelVersion>@</modelVersion>\n    <packaging>war</packaging>@' pom.xml && \
    rm target -rf && \
    rm target_heroku -rf && \
    mvn clean && \
    mvn package

FROM alpine:3.18
RUN apk update && \
    apk add openjdk8-jre-base && \
    rm /var/cache/apk/* -rf && \
    wget -O /tmp/tomcat.tar.gz \
        https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.78/bin/apache-tomcat-9.0.78.tar.gz && \
    mkdir -p /opt/tomcat && \
    tar xf /tmp/tomcat.tar.gz --strip-components 1 --directory /opt/tomcat && \
    rm /tmp/tomcat.tar.gz && \
    rm /opt/tomcat/webapps/* -rf

COPY --from=builder --link /build/puzzle15/target/Puzzle15-1.0-SNAPSHOT.war /opt/tomcat/webapps/puzzle15.war
EXPOSE 8080
WORKDIR /opt/tomcat
CMD [ "/opt/tomcat/bin/catalina.sh", "run" ]
