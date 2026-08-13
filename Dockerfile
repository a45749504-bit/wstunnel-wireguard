FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    wireguard-tools \
    curl \
    iproute2 \
    iptables \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Скачиваем wstunnel
RUN curl -fLo /usr/local/bin/wstunnel \
    https://github.com/erebe/wstunnel/releases/latest/download/wstunnel_linux_amd64 \
    && chmod +x /usr/local/bin/wstunnel

# Скрипт генерации ключей и запуска
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# WireGuard UDP порт (фиксированный)
EXPOSE 51820/udp

# Порт для wstunnel назначается через переменную PORT в entrypoint.sh
# НЕ используем EXPOSE с переменной — Docker не поддерживает это

ENTRYPOINT ["/entrypoint.sh"]
