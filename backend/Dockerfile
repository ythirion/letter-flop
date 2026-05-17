FROM eclipse-temurin:25

WORKDIR /app

COPY . .

RUN apt-get update && apt-get install -y maven && mvn package -DskipTests

EXPOSE 8080

CMD ["java", "-jar", "target/letterflop-0.0.1-SNAPSHOT.jar"]
