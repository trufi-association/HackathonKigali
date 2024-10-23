FROM openjdk:21-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install -y wget

WORKDIR /app
ADD ./app .

RUN wget https://github.com/opentripplanner/OpenTripPlanner/releases/download/v2.2.0/otp-2.2.0-shaded.jar

EXPOSE 8080 8081

ENTRYPOINT [ "sh", "./run.sh" ]