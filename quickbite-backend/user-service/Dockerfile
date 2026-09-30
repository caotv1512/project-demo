# ==========================================================================
#  Dockerfile MULTI-STAGE cho user-service (Session 08)
#
#  Khác Session 04 ở chỗ: không cần build JAR trên máy trước nữa.
#  Toàn bộ việc biên dịch diễn ra ngay BÊN TRONG quá trình build image.
#
#  Bản đơn tầng cũ vẫn giữ ở Dockerfile.single để đối chiếu.
# ==========================================================================

# ------------------- TẦNG 1: BUILDER (nặng, chỉ để biên dịch) -------------------
# Dùng JDK vì cần trình biên dịch. Tầng này KHÔNG đi vào image cuối.
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app

# Chép các file ÍT THAY ĐỔI trước — để Docker tái dùng được cache.
# Sửa code Java thì 3 dòng dưới vẫn dùng lại cache, không tải lại thư viện.
COPY gradlew ./
COPY gradle ./gradle
COPY build.gradle settings.gradle ./

# Tải sẵn dependency thành một layer riêng.
# --no-daemon: không giữ tiến trình Gradle nền, phù hợp môi trường container.
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

# Mã nguồn thay đổi thường xuyên nhất nên để CUỐI cùng.
COPY src ./src
RUN ./gradlew bootJar --no-daemon

# ------------------- TẦNG 2: RUNTIME (nhẹ, để chạy thật) -------------------
# Dùng JRE, không cần JDK. Bắt đầu lại từ image sạch.
FROM eclipse-temurin:17-jre-alpine AS runtime
WORKDIR /app

# Chỉ lấy DUY NHẤT file JAR từ tầng builder.
# Mã nguồn, Gradle, JDK đều bị bỏ lại — không có trong image cuối.
COPY --from=builder /app/build/libs/user-service.jar app.jar

EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
