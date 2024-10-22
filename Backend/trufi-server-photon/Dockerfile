FROM openjdk:21-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install -y wget

WORKDIR /app
RUN wget -O photon.jar https://github.com/komoot/photon/releases/download/0.4.2/photon-0.4.2.jar

EXPOSE 2322

ENTRYPOINT ["java", "-jar", "photon.jar"]