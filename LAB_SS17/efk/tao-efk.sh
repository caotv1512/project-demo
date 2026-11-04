#!/usr/bin/env bash
# Dung cum EFK cho Session 17. Can mang quickbite5-net cua session-05 ton tai.
set -e
cd "$(dirname "$0")"

if ! docker network inspect quickbite5-net >/dev/null 2>&1; then
  echo "❌ Chua co mang quickbite5-net."
  echo "   Bat he thong QuickBite truoc:"
  echo "     cd ../../session-05 && ./start-all.sh"
  exit 1
fi

for P in 9200 5601 24224; do
  if lsof -nP -iTCP:"$P" -sTCP:LISTEN >/dev/null 2>&1 \
     && ! docker ps --format '{{.Ports}}' | grep -q ":$P->"; then
    echo "❌ Cong $P dang bi tien trinh khac chiem (khong phai cum EFK)."
    echo "   Xem ai dang giu:  lsof -nP -iTCP:$P -sTCP:LISTEN"
    exit 1
  fi
done

echo "==> Build Fluentd image va dung ca ba container..."
docker compose up -d --build

echo "==> Doi Elasticsearch san sang (toi da 180 giay)..."
for i in $(seq 1 90); do
  curl -fsS -m 3 http://127.0.0.1:9200/_cluster/health >/dev/null 2>&1 && break
  sleep 2
done
if ! curl -fsS -m 3 http://127.0.0.1:9200/_cluster/health >/dev/null 2>&1; then
  echo "    ⚠️  Elasticsearch chua phan hoi. Xem log:"
  echo "        docker compose logs --tail=40 elasticsearch"
  exit 1
fi

echo "==> Doi Kibana san sang (toi da 240 giay)..."
for i in $(seq 1 120); do
  curl -fsS -m 3 http://127.0.0.1:5601/api/status >/dev/null 2>&1 && break
  sleep 2
done

echo
echo "Cum EFK da chay."
echo "  Elasticsearch : http://127.0.0.1:9200"
echo "  Kibana        : http://127.0.0.1:5601"
echo "  Fluentd       : 127.0.0.1:24224"
echo "  Kiem tra      : ./check.sh"
