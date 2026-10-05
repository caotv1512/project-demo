# VPS giả lập: Ubuntu Server 24.04 + SSH, để học viên luyện BÀI 1–3 ngay trên máy mình.
FROM ubuntu:24.04

# Cài đúng những gói mà một VPS Ubuntu mới tinh đã có sẵn
RUN apt-get update && apt-get install -y --no-install-recommends \
      openssh-server sudo nano curl ca-certificates iproute2 \
      less procps gnupg ufw \
 && rm -rf /var/lib/apt/lists/*

# sshd cần thư mục này mới chạy được
RUN mkdir -p /run/sshd

# Đặt mật khẩu root để BÀI 2 có thể demo "đăng nhập bằng mật khẩu" trước khi tắt nó đi
RUN echo 'root:quickbite' | chpasswd \
 && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
