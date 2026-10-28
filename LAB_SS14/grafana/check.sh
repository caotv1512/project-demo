#!/usr/bin/env bash
# Kiem tra nhanh: dang o buoc nao cua Session 14.
# Tu do cong tu container dang chay; khong co thi dung bien hoac mac dinh 3000.
PORT=$(docker ps --format '{{.Names}} {{.Ports}}' 2>/dev/null \
  | awk '/^quickbite-grafana/{ if (match($0,/:[0-9]+->3000/)) { s=substr($0,RSTART+1); sub(/->3000.*/,"",s); print s } }' | head -1)
PORT="${PORT:-${GRAFANA_HOST_PORT:-3000}}"
G="http://admin:${GF_ADMIN_PASSWORD:-quickbite_lab_2026}@localhost:$PORT"
pass=0; fail=0
ok(){ printf '  %-54s ✅\n' "$1"; pass=$((pass+1)); }
no(){ printf '  %-54s ❌  %s\n' "$1" "$2"; fail=$((fail+1)); }

echo "───────────────────────────────────────────────────────────────"
echo "  KIEM TRA DASHBOARD GRAFANA — SESSION 14   (cong $PORT)"
echo "───────────────────────────────────────────────────────────────"

docker ps --format '{{.Names}}' | grep -q '^quickbite-prometheus$' \
  && ok "Dieu kien: Prometheus (SS13) dang chay" \
  || no "Dieu kien: Prometheus (SS13) dang chay" "cd ../../LAB_SS13/monitoring && ./tao-monitoring.sh"

docker ps --format '{{.Names}}' | grep -q '^quickbite-grafana$' \
  && ok "PHAN 1: container Grafana dang chay" || no "PHAN 1: container Grafana dang chay" "./tao-grafana.sh"

curl -s "http://localhost:$PORT/api/health" | grep -q '"database": *"ok"' \
  && ok "PHAN 1: Grafana phan hoi" || no "PHAN 1: Grafana phan hoi" "docker compose logs grafana"

DS=$(curl -s "$G/api/datasources" 2>/dev/null)
echo "$DS" | grep -q '"type":"prometheus"' \
  && ok "PHAN 2: co Data Source Prometheus" || no "PHAN 2: co Data Source Prometheus" "xem muc 2.2"

DSUID=$(echo "$DS" | python3 -c "
import json,sys
try:
    for d in json.load(sys.stdin):
        if d['type']=='prometheus': print(d['uid']); break
except Exception: pass" 2>/dev/null)

echo "$DS" | grep -q 'http://quickbite-prometheus:9090' \
  && ok "PHAN 2: URL dung ten container, khong phai localhost" \
  || no "PHAN 2: URL dung ten container" "sua thanh http://quickbite-prometheus:9090"

if [ -n "$DSUID" ]; then
  curl -s "$G/api/datasources/uid/$DSUID/health" 2>/dev/null | grep -q '"status":"OK"' \
    && ok "PHAN 2: Save & test tra ve OK" || no "PHAN 2: Save & test" "Grafana va Prometheus khac mang?"
else
  no "PHAN 2: Save & test" "chua co data source"
fi

SEARCH=$(curl -s "$G/api/search?type=dash-db" 2>/dev/null)
echo "$SEARCH" | grep -q 'VPS Monitoring' \
  && ok "PHAN 3: da import dashboard VPS (ID 1860)" || no "PHAN 3: dashboard VPS" "import ID 1860, xem muc 3.3"
echo "$SEARCH" | grep -q 'JVM Monitoring' \
  && ok "PHAN 4: da import dashboard JVM (ID 4701)" || no "PHAN 4: dashboard JVM" "import ID 4701, xem muc 4.3"

if [ -n "$DSUID" ]; then
  APPS=$(curl -s "$G/api/datasources/proxy/uid/$DSUID/api/v1/label/application/values" 2>/dev/null \
    | python3 -c "import json,sys;print(','.join(json.load(sys.stdin).get('data') or []))" 2>/dev/null)
  [ -n "$APPS" ] \
    && ok "PHAN 4: bo loc Application thay: $APPS" \
    || no "PHAN 4: bo loc Application" "service chua co Micrometer — lam lai SS13 BAI 2"
fi

if [ -n "$DSUID" ]; then
  CPU=$(curl -s -G "$G/api/datasources/proxy/uid/$DSUID/api/v1/query" \
    --data-urlencode 'query=100 * (1 - avg(rate(node_cpu_seconds_total{mode="idle",job="vps-hardware"}[5m])))' 2>/dev/null \
    | python3 -c "
import json,sys
try:
    r=json.load(sys.stdin)['data']['result']
    print('%.2f'%float(r[0]['value'][1]) if r else '')
except Exception: print('')" 2>/dev/null)
  [ -n "$CPU" ] \
    && ok "PHAN 3: panel VPS co du lieu (CPU ${CPU}%)" \
    || no "PHAN 3: panel VPS co du lieu" "chua chon bo loc o dau dashboard — xem muc 3.5"

  HEAP=$(curl -s -G "$G/api/datasources/proxy/uid/$DSUID/api/v1/query" \
    --data-urlencode 'query=sum(jvm_memory_used_bytes{area="heap"})/1024/1024' 2>/dev/null \
    | python3 -c "
import json,sys
try:
    r=json.load(sys.stdin)['data']['result']
    print('%.1f'%float(r[0]['value'][1]) if r else '')
except Exception: print('')" 2>/dev/null)
  [ -n "$HEAP" ] \
    && ok "PHAN 4: panel JVM co du lieu (heap ${HEAP} MB)" \
    || no "PHAN 4: panel JVM co du lieu" "service chua co Micrometer — xem SS13 BAI 2"
fi

curl -s "$G/api/v1/provisioning/alert-rules" 2>/dev/null | grep -q 'Service Down Alert' \
  && ok "PHAN 5: da tao Alert Rule" || no "PHAN 5: da tao Alert Rule" "xem muc 5.4"

echo "───────────────────────────────────────────────────────────────"
echo "  TRANG THAI ALERT"
curl -s "$G/api/prometheus/grafana/api/v1/rules" 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print('    (chua doc duoc)'); raise SystemExit
gs=d.get('data',{}).get('groups',[])
if not gs: print('    (chua co alert rule nao)')
for g in gs:
    for r in g.get('rules',[]):
        al=r.get('alerts') or []
        print('    %-24s %s' % (r.get('name','?'), r.get('state','?')))
        for a in al:
            if a.get('state')!='Normal':
                print('        %-28s %s' % (a['labels'].get('instance','?'), a.get('state')))" 2>/dev/null

echo "───────────────────────────────────────────────────────────────"
printf "  KET QUA: %d pass / %d fail\n" "$pass" "$fail"
[ "$fail" -eq 0 ] && echo "  🎉 San sang len lop!" || echo "  Lam not cac muc ❌ o tren."
echo "───────────────────────────────────────────────────────────────"
