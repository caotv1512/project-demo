#!/usr/bin/env bash
# Kiem tra nhanh toan bo he thong - dung truoc khi len lop.
cd "$(dirname "$0")"
PASS=0; FAIL=0
chk() { printf "  %-46s" "$1"; if eval "$2" >/dev/null 2>&1; then echo "✅"; PASS=$((PASS+1)); else echo "❌"; FAIL=$((FAIL+1)); fi; }

echo "🔍 KIEM TRA HE THONG DEMO QUICKBITE"
echo "── Moi truong ─────────────────────────────────────────"
chk "Docker daemon dang chay"            "docker info"
chk "Docker Compose V2"                  "docker compose version"
echo "── Container ──────────────────────────────────────────"
chk "quickbite-db dang chay"             "docker ps --filter name=^quickbite-db$ --filter status=running -q | grep ."
chk "quickbite-user dang chay"           "docker ps --filter name=^quickbite-user$ --filter status=running -q | grep ."
chk "mang quickbite-net ton tai"         "docker network ls | grep quickbite-net"
echo "── Database ───────────────────────────────────────────"
chk "PostgreSQL nhan ket noi"            "docker exec quickbite-db pg_isready -U postgres"
chk "DB quickbite_user_db da tao"        "docker exec quickbite-db psql -U postgres -lqt | grep quickbite_user_db"
chk "User quickbite_user da tao"         "docker exec quickbite-db psql -U postgres -c '\du' | grep quickbite_user"
echo "── Ung dung ───────────────────────────────────────────"
chk "user-service /actuator/health = UP" "curl -fsS http://localhost:8081/actuator/health | grep '\"status\":\"UP\"'"
chk "user-service /api/users tra du lieu" "curl -fsS http://localhost:8081/api/users | grep quickbite.vn"
chk "Service Discovery (ping ten service)" "docker exec quickbite-user ping -c 1 quickbite-db"
echo "───────────────────────────────────────────────────────"
echo "  KET QUA: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ] && echo "  🎉 San sang len lop!" || echo "  ⚠️  Chay ./start-all.sh roi kiem tra lai."
