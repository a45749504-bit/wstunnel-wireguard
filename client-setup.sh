#!/bin/bash
# ============================================
# Настройка клиента WireGuard + Wstunnel
# для Android (Termux) или Linux
# ============================================

set -e

SERVER_URL="${1:-}"
SECRET="${2:-}"

if [ -z "$SERVER_URL" ] || [ -z "$SECRET" ]; then
    echo "Использование: bash client-setup.sh <wss://your-app.onrender.com> <secret>"
    echo ""
    echo "Пример:"
    echo "  bash client-setup.sh wss://myvpn.onrender.com my-super-secret-key"
    exit 1
fi

echo "🔧 Установка зависимостей..."
if command -v apt-get &> /dev/null; then
    apt-get update -qq
    apt-get install -y -qq wireguard-tools curl tar
elif command -v pkg &> /dev/null; then
    # Termux
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg install -y wireguard-tools curl tar
else
    echo "⚠️  Не удалось определить пакетный менеджер"
    exit 1
fi

echo "📥 Скачивание wstunnel..."
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    WSTUNNEL_URL="https://github.com/erebe/wstunnel/releases/latest/download/wstunnel_android_arm64.tar.gz"
    WSTUNNEL_FILE="wstunnel_android_arm64.tar.gz"
elif [ "$ARCH" = "x86_64" ]; then
    WSTUNNEL_URL="https://github.com/erebe/wstunnel/releases/latest/download/wstunnel_linux_amd64"
    WSTUNNEL_FILE="wstunnel_linux_amd64"
else
    echo "⚠️  Архитектура $ARCH может быть не поддержана."
    echo "   Проверь релизы: https://github.com/erebe/wstunnel/releases"
    exit 1
fi

if [ "$ARCH" = "aarch64" ]; then
    curl -fLo "$WSTUNNEL_FILE" "$WSTUNNEL_URL"
    tar -xzf "$WSTUNNEL_FILE" wstunnel
    rm "$WSTUNNEL_FILE"
else
    curl -fLo wstunnel "$WSTUNNEL_URL"
fi

chmod +x wstunnel

echo "🔑 Генерация ключей WireGuard..."
CLIENT_PRIVATE=$(wg genkey)
CLIENT_PUBLIC=$(echo "$CLIENT_PRIVATE" | wg pubkey)
PRESHARED=$(wg genpsk)

echo ""
echo "=========================================="
echo "  КЛИЕНТСКИЕ КЛЮЧИ (сохрани их!)"
echo "=========================================="
echo ""
echo "  Client Private Key: ${CLIENT_PRIVATE}"
echo "  Client Public Key:  ${CLIENT_PUBLIC}"
echo "  PresharedKey:       ${PRESHARED}"
echo ""
echo "⚠️  ВСТАВЬ Client Public Key в Environment Variables"
echo "    на Render.com как CLIENT_PUBLIC_KEY"
echo "    и PresharedKey на сервере (или используй новый)."
echo ""
echo "=========================================="
echo ""

# Создание конфига WireGuard
mkdir -p wireguard-config
cat > wireguard-config/wg-client.conf <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE}
Address = 10.200.200.2/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = SERVER_PUBLIC_KEY_HERE
PresharedKey = ${PRESHARED}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = 127.0.0.1:51820
PersistentKeepalive = 25
EOF

echo "✅ Конфиг WireGuard сохранён: wireguard-config/wg-client.conf"
echo "   Замени SERVER_PUBLIC_KEY_HERE на публичный ключ сервера."
echo ""

# Создание скрипта запуска
cat > start-tunnel.sh <<EOF
#!/bin/bash
# WireGuard + Wstunnel Client
# Запускай этот скрипт перед включением WireGuard!

echo "🚀 Запуск wstunnel клиента..."
echo "   Сервер: ${SERVER_URL}"
echo "   Локальный UDP порт: 51820"
echo ""

./wstunnel client \
    --http-upgrade-path-prefix "${SECRET}" \
    -L "udp://51820:localhost:51820?timeout_sec=0" \
    "${SERVER_URL}"
EOF

chmod +x start-tunnel.sh

echo "✅ Скрипт запуска создан: start-tunnel.sh"
echo ""
echo "📋 Порядок запуска на Android:"
echo "   1. termux: ./start-tunnel.sh"
echo "   2. WireGuard app: импортируй wg-client.conf и включи"
echo ""
echo "📋 Порядок запуска на Linux:"
echo "   1. sudo ./start-tunnel.sh"
echo "   2. sudo wg-quick up wireguard-config/wg-client.conf"
