#!/usr/bin/env bash
# Kiem tra dieu kien va ket qua bai lab Session 17 (EFK tap trung log).
cd "$(dirname "$0")"
HERE="$PWD"
LAB="$HERE/.."
STACK="$HERE/../../session-05/stack"
P=0; F=0
chk(){ printf "  %-54s" "$1"; if ( eval "$2" ) >/dev/null 2>&1; then echo "✅"; P=$((P+1)); else printf "❌  %s\n" "$3"; F=$((F+1)); fi; }

PORT=$(grep -E '^GATEWAY_HOST_PORT=' "$STACK/.env" 2>/dev/null | cut -d= -f2)
PORT="${PORT:-8000}"

echo "───────────────────────────────────────────────────────────────"
echo "  KIEM TRA BAI LAB EFK — SESSION 17   (gateway cong $PORT)"
echo "───────────────────────────────────────────────────────────────"

echo "── Dieu kien can ──────────────────────────────────────────────"
chk "Docker daemon dang chay"          "docker info" "mo Docker Desktop"
chk "mang quickbite5-net ton tai"      "docker network inspect quickbite5-net" "cd ../../session-05 && ./start-all.sh"
chk "5 container session-05 dang chay" "[ \$(docker ps --filter name=quickbite5- --filter status=running -q | wc -l) -ge 5 ]" "cd ../../session-05 && ./start-all.sh"

echo "── PHAN 1: ba container EFK ───────────────────────────────────"
chk "quickbite-elasticsearch dang chay" "docker ps --filter name=quickbite-elasticsearch --filter status=running -q | grep -q ." "./tao-efk.sh"
chk "quickbite-kibana dang chay"        "docker ps --filter name=quickbite-kibana --filter status=running -q | grep -q ." "./tao-efk.sh"
chk "quickbite-fluentd dang chay"       "docker ps --filter name=quickbite-fluentd --filter status=running -q | grep -q ." "./tao-efk.sh"
chk "Elasticsearch tra loi cong 9200"   "curl -fsS -m 5 http://127.0.0.1:9200/_cluster/health" "docker compose logs --tail=40 elasticsearch"
chk "Kibana tra loi cong 5601"          "curl -fsS -m 10 http://127.0.0.1:5601/api/status" "Kibana can 1-2 phut de khoi dong"

echo "── PHAN 2: logging driver cua 4 service ───────────────────────"
for c in quickbite5-order quickbite5-user quickbite5-restaurant quickbite5-notification; do
  chk "$c dung driver fluentd" \
      "[ \"\$(docker inspect --format '{{.HostConfig.LogConfig.Type}}' $c 2>/dev/null)\" = fluentd ]" \
      "lam muc 3.3 (up -d --force-recreate voi file chong)"
done

echo "── PHAN 3: log da vao Elasticsearch ───────────────────────────"
chk "co index quickbite-*" \
    "curl -fsS -m 5 'http://127.0.0.1:9200/_cat/indices/quickbite-*?h=index' | grep -q quickbite-" \
    "dat 1 don roi doi 10 giay: ../test-trace-request.sh"
chk "field service.name da duoc tach" \
    "curl -fsS -m 5 'http://127.0.0.1:9200/quickbite-*/_search?q=service.name:order-service&size=1' | grep -q '\"service.name\"'" \
    "parser chua chay — xem muc 5.2"
chk "field trace.id da duoc tach" \
    "curl -fsS -m 5 'http://127.0.0.1:9200/quickbite-*/_search?size=1&q=_exists_:trace.id' | grep -q '\"trace.id\"'" \
    "dat don bang ../test-trace-request.sh"

echo "── PHAN 4: bao mat ────────────────────────────────────────────"
printf "  %-54s" "ba cong EFK chi bind tren 127.0.0.1"
if docker ps --format '{{.Names}}\t{{.Ports}}' | grep -E 'quickbite-(elasticsearch|kibana|fluentd)' | grep -q '0\.0\.0\.0'; then
  echo "❌  co cong mo ra 0.0.0.0 — xem lai docker-compose.yml"; F=$((F+1))
else
  echo "✅"; P=$((P+1))
fi
LOT=$(curl -fsS -m 5 'http://127.0.0.1:9200/quickbite-*/_search?size=200&q=_exists_:message' 2>/dev/null \
      | grep -icE 'password=|passwd=|Bearer [A-Za-z0-9]|eyJhbGciOi' || true)
printf "  %-54s" "log trong Elasticsearch khong lot bi mat"
if [ "${LOT:-0}" -eq 0 ]; then echo "✅"; P=$((P+1)); else echo "❌  tim thay $LOT doan — xem muc 6.3"; F=$((F+1)); fi

echo "───────────────────────────────────────────────────────────────"
echo "  KET QUA: $P pass / $F fail"
[ "$F" -eq 0 ] && echo "  🎉 San sang len lop!" || echo "  ⚠️  Lam theo goi y o cot ben phai."
echo "───────────────────────────────────────────────────────────────"
