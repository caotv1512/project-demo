# ==========================================================
#  Dockerfile - restaurant-service (Java 21)
#  So sanh voi user-service: CHI KHAC DUNG MOT CON SO o dong FROM.
#  Day chinh la luan diem "da dang cong nghe" cua mo hinh nhieu container.
# ==========================================================
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

COPY build/libs/restaurant-service.jar app.jar

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "app.jar"]
