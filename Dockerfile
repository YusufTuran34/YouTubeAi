# Build stage
FROM gradle:8.2.1-jdk17 AS build
WORKDIR /workspace
COPY . .
RUN gradle clean build -x test

# Runtime stage
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /workspace/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
