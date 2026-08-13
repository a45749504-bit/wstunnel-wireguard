FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    wireguard-tools \
    curl \
    tar \
    iproute2 \
    iptables \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Скачиваем wstunnel (версия 10.6.2, linux amd64)
# Архив tar.gz содержит папку с бинарником внутри
RUN curl -fLo /tmp/wstunnel.tar.gz \
    https://github.com/erebe/wstunnel/releases/download/v10.6.2/wstunnel_10.6.2_linux_amd64.tar.gz \
    && tar -xzf /tmp/wstunnel.tar.gz -C /tmp \
    && cp /tmp/wstunnel_10.6.2_linux_amd64/wstunnel /usr/local/bin/wstunnel \
    && chmod +x /usr/local/bin/wstunnel \
    && rm -rf /tmp/wstunnel.tar.gz /tmp/wstunnel_10.6.2_linux_amd64 \
    && wstunnel --version

# Скрипт генерации ключей и запуска
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# WireGuard UDP порт
EXPOSE 51820/udp

ENTRYPOINT ["/entrypoint.sh"]
