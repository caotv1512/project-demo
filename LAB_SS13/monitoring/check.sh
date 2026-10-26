#!/usr/bin/env bash
# Kiem tra nhanh: dang o buoc nao cua Session 13.
pass=0; fail=0
ok(){ printf '  %-52s ✅\n' "$1"; pass=$((pass+1)); }
no(){ printf '  %-52s ❌  %s\n' "$1" "$2"; fail=$((fail+1)); }
P="docker exec quickbite-prometheus wget -qO-"

echo "───────────────────────────────────────────────────────────────"
echo "  KIEM TRA GIAM SAT PROMETHEUS — SESSION 13"
echo "───────────────────────────────────────────────────────────────"

docker ps --format '{{.Names}}' | grep -q '^quickbite5-order$' \
  && ok "Session 05 dang chay" || no "Session 05 dang chay" "cd ../../session-05 && ./start-all.sh"

# --- BAI 2 ---
grep -q 'micrometer-registry-prometheus' ../../session-05/stack/order-service/build.gradle 2>/dev/null \
  && ok "BAI 2: order-service da them Micrometer" || no "BAI 2: order-service da them Micrometer" "xem muc 2.2"

grep -A3 'exposure' ../../session-05/stack/order-service/src/main/resources/application.yml 2>/dev/null | grep -q 'prometheus' \
  && ok "BAI 2: application.yml da include prometheus" || no "BAI 2: application.yml da include prometheus" "xem muc 2.3"

docker exec quickbite5-order sh -c 'wget -qO- http://localhost:8083/actuator/prometheus 2>/dev/null | head -1' 2>/dev/null | grep -q '#' \
  && ok "BAI 2: /actuator/prometheus tra ve metrics" || no "BAI 2: /actuator/prometheus tra ve metrics" "build lai service (muc 2.4)"

docker exec quickbite5-order sh -c 'wget -qO- http://localhost:8083/actuator/prometheus 2>/dev/null' 2>/dev/null | grep -q 'application="order-service"' \
  && ok "BAI 2: co nhan chung application=" || no "BAI 2: co nhan chung application=" "them metrics.tags (muc 2.3)"

# --- BAI 3 ---
docker ps --format '{{.Names}}' | grep -q '^quickbite-prometheus$' \
  && ok "BAI 3: container Prometheus dang chay" || no "BAI 3: container Prometheus dang chay" "chay ./tao-monitoring.sh"

$P http://localhost:9090/-/healthy >/dev/null 2>&1 \
  && ok "BAI 3: Prometheus phan hoi" || no "BAI 3: Prometheus phan hoi" "docker compose logs prometheus"

[ "$(docker inspect quickbite-prometheus --format '{{.HostConfig.PortBindings}}' 2>/dev/null)" = "map[]" ] \
  && ok "BAI 3: Prometheus KHONG mo cong ra ngoai" || no "BAI 3: Prometheus KHONG mo cong ra ngoai" "go khai bao ports trong compose"

# --- BAI 4 ---
docker ps --format '{{.Names}}' | grep -q '^quickbite-node-exporter$' \
  && ok "BAI 4: container Node Exporter dang chay" || no "BAI 4: container Node Exporter dang chay" "chay ./tao-monitoring.sh"

[ "$(docker inspect quickbite-node-exporter --format '{{.HostConfig.PortBindings}}' 2>/dev/null)" = "map[]" ] \
  && ok "BAI 4: Node Exporter KHONG mo cong ra ngoai" || no "BAI 4: Node Exporter KHONG mo cong ra ngoai" "go khai bao ports"

# --- Trang thai targets ---
echo "───────────────────────────────────────────────────────────────"
echo "  TRANG THAI TARGETS"
UP=$($P "http://localhost:9090/api/v1/query?query=up" 2>/dev/null)
if [ -n "$UP" ]; then
  echo "$UP" | python3 -c "
import json,sys
try:
    rs=json.load(sys.stdin)['data']['result']
except Exception:
    print('    (chua doc duoc)'); sys.exit()
if not rs: print('    (chua co du lieu — doi them 15s)')
for r in rs:
    m=r['metric']; v=r['value'][1]
    print(f\"    {m.get('job','?'):20} {m.get('instance','?'):24} up={v}  {'✅' if v=='1' else '❌'}\")" 2>/dev/null
  DOWN=$($P "http://localhost:9090/api/v1/targets" 2>/dev/null | python3 -c "
import json,sys
try:
    for t in json.load(sys.stdin)['data']['activeTargets']:
        if t['health']!='up': print(f\"    {t['scrapeUrl']}  ->  {t.get('lastError','')[:60]}\")
except Exception: pass" 2>/dev/null)
  [ -n "$DOWN" ] && { echo "  Ly do target DOWN:"; echo "$DOWN"; }
else
  echo "    (Prometheus chua chay)"
fi

echo "───────────────────────────────────────────────────────────────"
printf "  KET QUA: %d pass / %d fail\n" "$pass" "$fail"
[ "$fail" -eq 0 ] && echo "  🎉 San sang len lop!" || echo "  Lam not cac muc ❌ o tren."
echo "───────────────────────────────────────────────────────────────"
