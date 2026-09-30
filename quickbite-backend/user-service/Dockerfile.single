# ==========================================================
#  Dockerfile - user-service (Java 17)
#  Giong het cau truc day trong Session 04.
# ==========================================================

# 1. Dinh nghia Base Image (JRE Alpine sieu nhe)
FROM eclipse-temurin:17-jre-alpine

# 2. Thiet lap thu muc lam viec mac dinh trong container
WORKDIR /app

# 3. Sao chep file JAR da build tu host vao container
COPY build/libs/user-service.jar app.jar

# 4. Khai bao cong lang nghe noi bo (chi mang y nghia tai lieu hoa)
EXPOSE 8081

# 5. Lenh khoi chay tien trinh chinh
#    Dung exec form (mang JSON) de java la PID 1 -> nhan duoc SIGTERM khi docker stop
ENTRYPOINT ["java", "-jar", "app.jar"]
