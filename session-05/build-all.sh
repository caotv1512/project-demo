#!/usr/bin/env bash
# Build JAR cho ca 5 service bang Gradle TRONG DOCKER (khong can cai JDK tren may).
set -euo pipefail
cd "$(dirname "$0")"
SERVICES=(user-service restaurant-service order-service notification-service api-gateway)
[ $# -gt 0 ] && SERVICES=("$@")
for s in "${SERVICES[@]}"; do
  echo "🔨 Build $s ..."
  docker run --rm \
    -v "$PWD/stack/$s":/home/gradle/project \
    -v quickbite-gradle-cache:/home/gradle/.gradle \
    -w /home/gradle/project gradle:8.10-jdk17 gradle bootJar --no-daemon -q
  ls -lh "stack/$s/build/libs/$s.jar"
done
echo "✅ Xong tat ca."
