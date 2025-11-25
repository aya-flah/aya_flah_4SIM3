FROM openjdk:17.0.1-jdk-slim

WORKDIR /app

COPY target/*.jar /app/app.jar

EXPOSE 8089

ENTRYPOINT ["java", "-jar", "/app/app.jar"]