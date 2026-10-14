#!/usr/bin/env bash
# Kiem tra nhanh: Nginx va reverse proxy dang o trang thai nao.
pass=0; fail=0
ok(){ printf '  %-50s ✅\n' "$1"; pass=$((pass+1)); }
no(){ printf '  %-50s ❌  %s\n' "$1" "$2"; fail=$((fail+1)); }

echo "─────────────────────────────────────────────────────────────"
echo "  KIEM TRA REVERSE PROXY — SESSION 11"
echo "─────────────────────────────────────────────────────────────"

docker ps --format '{{.Names}}' | grep -q '^vps11$' \
  && ok "container vps11 dang chay" || no "container vps11 dang chay" "chay ./tao-vps.sh"

docker ps --format '{{.Names}}' | grep -q '^quickbite5-gateway$' \
  && ok "API Gateway (Session 05) dang chay" || no "API Gateway (Session 05) dang chay" "cd ../../session-05 && ./start-all.sh"

docker exec vps11 nginx -v >/dev/null 2>&1 \
  && ok "Nginx da cai trong VPS" || no "Nginx da cai trong VPS" "xem BAI 1"

docker exec vps11 test -f /etc/nginx/conf.d/quickbite.conf 2>/dev/null \
  && ok "da co /etc/nginx/conf.d/quickbite.conf" || no "da co /etc/nginx/conf.d/quickbite.conf" "xem BAI 2"

docker exec vps11 test ! -e /etc/nginx/sites-enabled/default 2>/dev/null \
  && ok "da go site mac dinh cua Ubuntu" || no "da go site mac dinh cua Ubuntu" "xem Thi nghiem 1"

docker exec vps11 nginx -t >/dev/null 2>&1 \
  && ok "nginx -t: cu phap hop le" || no "nginx -t: cu phap hop le" "chay 'docker exec vps11 nginx -t' xem loi"

docker exec vps11 curl -fsS --max-time 6 http://quickbite5-gateway:8080/api/v1/users >/dev/null 2>&1 \
  && ok "VPS goi duoc toi API Gateway" || no "VPS goi duoc toi API Gateway" "kiem tra mang quickbite5-net"

code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 http://localhost:8880/api/v1/users)
[ "$code" = "200" ] && ok "goi API QUA Nginx (HTTP 8880)" \
  || { [ "$code" = "301" ] && ok "cong 80 chuyen huong 301 sang HTTPS (da lam BAI 4)" \
       || no "goi API QUA Nginx (HTTP 8880)" "nhan duoc $code"; }

if [ "$code" = "301" ]; then
  curl -sk -o /dev/null -w '%{http_code}' --max-time 10 https://localhost:8443/api/v1/users | grep -q 200 \
    && ok "goi API QUA Nginx bang HTTPS (8443)" || no "goi API QUA Nginx bang HTTPS (8443)" "xem BAI 4"
fi

echo "─────────────────────────────────────────────────────────────"
printf "  KET QUA: %d pass / %d fail\n" "$pass" "$fail"
[ "$fail" -eq 0 ] && echo "  🎉 San sang len lop!" || echo "  Lam not cac muc ❌ o tren."
echo "─────────────────────────────────────────────────────────────"
