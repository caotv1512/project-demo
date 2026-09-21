#!/usr/bin/env bash
# ==========================================================================
#  build-jar.sh  -  Build file JAR MA KHONG CAN cai JDK/Gradle tren may host
#
#  Bang lenh thuc hanh day:   ./gradlew bootJar
#  Lenh do yeu cau may phai co JDK 17. Neu may GIANG VIEN chua cai JDK,
#  dung script nay thay the - ket qua ra dung y het:
#        <service>/build/libs/<service>.jar
#
#  Cach dung:
#      ./build-jar.sh                 # build user-service (mac dinh)
#      ./build-jar.sh user-service
#      ./build-jar.sh restaurant-service
# ==========================================================================
set -euo pipefail
cd "$(dirname "$0")"

SERVICE="${1:-user-service}"

case "$SERVICE" in
  user-service)       DIR="quickbite-backend/user-service";            JDK="17" ;;
  restaurant-service) DIR="bai-tap-1-restaurant/restaurant-service";   JDK="21" ;;
  *) echo "❌ Khong biet service '$SERVICE'. Dung: user-service | restaurant-service"; exit 1 ;;
esac

[ -d "$DIR" ] || { echo "❌ Khong tim thay thu muc $DIR"; exit 1; }

echo "🔨 Build $SERVICE (Java $JDK) bang Gradle trong Docker..."
echo "   (lan dau se tai image gradle + thu vien, cac lan sau rat nhanh nho cache)"

docker run --rm \
  -v "$PWD/$DIR":/home/gradle/project \
  -v quickbite-gradle-cache:/home/gradle/.gradle \
  -w /home/gradle/project \
  "gradle:8.10-jdk${JDK}" \
  gradle bootJar --no-daemon

echo
echo "✅ Xong:"
ls -lh "$DIR/build/libs/"
