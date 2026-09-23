#!/usr/bin/env bash
# Kiem tra nhanh he thong Session 05 truoc khi len lop.
cd "$(dirname "$0")"
PORT=$(grep -E '^GATEWAY_HOST_PORT=' stack/.env | cut -d= -f2)
P=0; F=0
chk(){ printf "  %-50s" "$1"; if eval "$2" >/dev/null 2>&1; then echo "✅"; P=$((P+1)); else echo "❌"; F=$((F+1)); fi; }

echo "🔍 KIEM TRA HE THONG SESSION 05 (gateway cong $PORT)"
echo "── Ha tang ────────────────────────────────────────────────"
chk "Docker daemon"                      "docker info"
chk "mang quickbite5-net ton tai"        "docker network ls | grep quickbite5-net"
chk "PostgreSQL nhan ket noi"            "docker exec quickbite5-db pg_isready -U postgres"
echo "── 6 container ────────────────────────────────────────────"
for c in db gateway user restaurant order notification; do
  chk "quickbite5-$c dang chay"          "docker ps --filter name=^quickbite5-$c\$ --filter status=running -q | grep ."
done
echo "── Database-per-service (4 DB) ────────────────────────────"
for d in user restaurant order notification; do
  chk "quickbite_${d}_db da tao"         "docker exec quickbite5-db psql -U postgres -lqt | grep quickbite_${d}_db"
done
echo "── Gateway dinh tuyen ─────────────────────────────────────"
chk "gateway /actuator/health = UP"      "curl -fsS http://localhost:$PORT/actuator/health | grep '\"status\":\"UP\"'"
chk "co du 4 route"                      "[ \$(curl -fsS http://localhost:$PORT/actuator/gateway/routes | grep -o route_id | wc -l) -eq 4 ]"
for r in users restaurants orders notifications; do
  chk "/api/v1/$r tra ve du lieu"        "curl -fsS http://localhost:$PORT/api/v1/$r"
done
echo "── Internal Ports (service phai AN khoi may that) ─────────"
for p in 8082 8083 8084; do
  chk "cong $p KHONG mo ra may that"     "! curl -fsS -m 2 http://localhost:$p/info"
done
echo "───────────────────────────────────────────────────────────"
echo "  KET QUA: $P pass / $F fail"
[ "$F" -eq 0 ] && echo "  🎉 San sang len lop!" || echo "  ⚠️  Chay ./start-all.sh roi kiem tra lai."
