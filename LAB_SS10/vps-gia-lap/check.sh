#!/usr/bin/env bash
# Kiem tra nhanh: VPS gia lap va cau hinh SSH dang o trang thai nao.
KEY="$HOME/.ssh/quickbite_vps_ed25519"
pass=0; fail=0
ok(){ printf '  %-48s ✅\n' "$1"; pass=$((pass+1)); }
no(){ printf '  %-48s ❌  %s\n' "$1" "$2"; fail=$((fail+1)); }

echo "─────────────────────────────────────────────────────────"
echo "  KIEM TRA VPS GIA LAP — SESSION 10"
echo "─────────────────────────────────────────────────────────"

docker ps --format '{{.Names}}' | grep -q '^vps-gia-lap$' \
  && ok "container vps-gia-lap dang chay" || no "container vps-gia-lap dang chay" "chay ./tao-vps.sh"

nc -z localhost 2222 2>/dev/null && ok "cong 2222 mo" || no "cong 2222 mo" "SSH chua len"

docker exec vps-gia-lap id deployer >/dev/null 2>&1 \
  && ok "user deployer da ton tai" || no "user deployer da ton tai" "lam BAI 2 muc 2.1"

docker exec vps-gia-lap id -nG deployer 2>/dev/null | grep -qw sudo \
  && ok "deployer thuoc nhom sudo" || no "deployer thuoc nhom sudo" "usermod -aG sudo deployer"

[ -f "$KEY" ] && ok "khoa SSH da tao o may local" || no "khoa SSH da tao o may local" "lam BAI 2 muc 2.2"

docker exec vps-gia-lap test -f /home/deployer/.ssh/authorized_keys 2>/dev/null \
  && ok "authorized_keys da co tren VPS" || no "authorized_keys da co tren VPS" "lam BAI 2 muc 2.3"

if [ -f "$KEY" ]; then
  ssh -i "$KEY" -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o BatchMode=yes -o ConnectTimeout=6 deployer@localhost true 2>/dev/null \
    && ok "dang nhap bang SSH key" || no "dang nhap bang SSH key" "xem BAI 5 - tim loi"
fi

cfg=$(docker exec vps-gia-lap sshd -T 2>/dev/null)
echo "$cfg" | grep -q '^permitrootlogin no'        && ok "da tat dang nhap root"      || no "da tat dang nhap root" "BAI 2 muc 2.5"
echo "$cfg" | grep -q '^passwordauthentication no' && ok "da tat dang nhap mat khau"  || no "da tat dang nhap mat khau" "BAI 2 muc 2.5"

docker exec vps-gia-lap ufw status 2>/dev/null | grep -q '^Status: active' \
  && ok "UFW dang bat" || no "UFW dang bat" "BAI 3 muc 3.3"

echo "─────────────────────────────────────────────────────────"
printf "  KET QUA: %d pass / %d fail\n" "$pass" "$fail"
[ "$fail" -eq 0 ] && echo "  🎉 San sang len lop!" || echo "  Lam not cac muc ❌ o tren."
echo "─────────────────────────────────────────────────────────"
