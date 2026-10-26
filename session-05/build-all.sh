#!/usr/bin/env bash
# Build JAR cho ca 5 service bang Gradle TRONG DOCKER (khong can cai JDK tren may).
set -euo pipefail
cd "$(dirname "$0")"
SERVICES=(user-service restaurant-service order-service notification-service api-gateway)
[ $# -gt 0 ] && SERVICES=("$@")
for s in "${SERVICES[@]}"; do
  echo "🔨 Build $s ..."
  # Gioi han RAM cho container build.
  # Khong dat -m thi JVM cua Gradle tu dinh co theo TOAN BO RAM cua may ao Docker,
  # trong khi 6 container session-05 da chiem san ~2.6 GB. May ao het RAM ->
  # kernel OOM-killer giet JVM -> "Gradle build daemon disappeared unexpectedly".
  docker run --rm -m "${BUILD_MEM:-1500m}" \
    -e GRADLE_OPTS="-Xmx384m -XX:MaxMetaspaceSize=256m" \
    -v "$PWD/stack/$s":/home/gradle/project \
    -v quickbite-gradle-cache:/home/gradle/.gradle \
    -w /home/gradle/project gradle:8.10-jdk17 gradle bootJar --no-daemon -q
  ls -lh "stack/$s/build/libs/$s.jar"
done
echo "✅ Xong tat ca."
