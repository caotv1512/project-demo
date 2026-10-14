# VPS giả lập cho Session 11 = VPS của Session 10 + Nginx đã cài sẵn.
# Dùng để học reverse proxy mà không cần thuê máy chủ thật.
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
      nginx \
      openssh-server sudo nano curl ca-certificates iproute2 \
      less procps gnupg ufw \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd

# Mật khẩu root chỉ dùng cho sandbox, để demo bước đăng nhập đầu tiên
RUN echo 'root:quickbite' | chpasswd \
 && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Chạy cả sshd lẫn nginx trong một container (VPS thật dùng systemd quản lý hai dịch vụ này)
RUN printf '#!/bin/sh\nnginx\nexec /usr/sbin/sshd -D -e\n' > /start.sh && chmod +x /start.sh

EXPOSE 22 80 443
CMD ["/start.sh"]
