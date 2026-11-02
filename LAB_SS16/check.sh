#!/usr/bin/env bash
# Kiem tra dieu kien va ket qua bai lab Session 16 (doc log Production).
cd "$(dirname "$0")"
HERE="$PWD"
STACK="$HERE/../session-05/stack"
P=0; F=0
chk(){ printf "  %-54s" "$1"; if ( eval "$2" ) >/dev/null 2>&1; then echo "✅"; P=$((P+1)); else printf "❌  %s\n" "$3"; F=$((F+1)); fi; }
dcl(){ ( cd "$STACK" && docker compose logs "$@" 2>/dev/null ); }

PORT=$(grep -E '^GATEWAY_HOST_PORT=' "$STACK/.env" 2>/dev/null | cut -d= -f2)
PORT="${PORT:-8000}"

echo "───────────────────────────────────────────────────────────────"
echo "  KIEM TRA BAI LAB DOC LOG — SESSION 16   (gateway cong $PORT)"
echo "───────────────────────────────────────────────────────────────"

echo "── Dieu kien can ──────────────────────────────────────────────"
chk "Docker daemon dang chay"            "docker info"  "mo Docker Desktop"
chk "5 container session-05 dang chay"   "[ \$(docker ps --filter name=quickbite5- --filter status=running -q | wc -l) -ge 5 ]" "cd ../session-05 && ./start-all.sh"
chk "gateway tra loi"                    "curl -fsS -m 5 http://localhost:$PORT/actuator/health"    "cd ../session-05 && ./start-all.sh"

echo "── PHAN 1: doc log ────────────────────────────────────────────"
chk "docker compose config --services ra 5 ten" \
    "[ \$( ( cd '$STACK' && docker compose config --services 2>/dev/null ) | wc -l) -eq 5 ]" "sai thu muc stack"
chk "order-service co log de doc"        "[ \$(dcl --tail 20 order-service | wc -l) -gt 0 ]" "container chua ghi log"

echo "── PHAN 2: log nghiep vu ──────────────────────────────────────"
chk "co dong [BUOC n] cua OrderController" "dcl order-service | grep -q 'BUOC'" \
    "dat 1 don: curl -X POST \"http://localhost:$PORT/api/v1/orders?userId=1&restaurantId=1\""
chk "co it nhat mot dong INFO"           "dcl --tail 200 order-service | grep -q 'INFO'" "container chua ghi log"

echo "── PHAN 3: log level ──────────────────────────────────────────"
chk "file log-debug.yml ton tai"         "[ -f '$HERE/log-debug.yml' ]"  "lam muc 3.1"
chk "log-debug.yml co cu phap hop le" \
    "( cd '$STACK' && docker compose -f docker-compose.yml -f '$HERE/log-debug.yml' config --quiet )" "sai cu phap YAML"
printf "  %-54s" "order-service dang o muc INFO (dung cho Prod)"
if dcl --tail 80 order-service | grep -q DEBUG; then
  echo "⚠️   dang o DEBUG — tra ve INFO o muc 3.4"
else
  echo "✅"; P=$((P+1))
fi

echo "── PHAN 5: bao mat log ────────────────────────────────────────"
LOT=$(dcl | grep -icE 'password=|passwd=|Authorization: Bearer|eyJhbGciOi')
printf "  %-54s" "log khong lot password/token"
if [ "${LOT:-0}" -eq 0 ]; then echo "✅"; P=$((P+1)); else echo "❌  tim thay $LOT dong — xem muc 5.1"; F=$((F+1)); fi

echo "───────────────────────────────────────────────────────────────"
echo "  KET QUA: $P pass / $F fail"
[ "$F" -eq 0 ] && echo "  🎉 San sang len lop!" || echo "  ⚠️  Lam theo goi y o cot ben phai."
echo "───────────────────────────────────────────────────────────────"
