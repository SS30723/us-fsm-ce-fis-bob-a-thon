FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

COPY target/order-service-1.0.0.jar app.jar

EXPOSE 8080

ENV DB_HOST=order-db \
    DB_PORT=5432 \
    DB_NAME=orders \
    DB_USER=orderuser \
    DB_PASS=orderpass

ENTRYPOINT ["java", "-jar", "app.jar"]
