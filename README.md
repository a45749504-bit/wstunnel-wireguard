# WireGuard + Wstunnel на Render.com

Полноценный VPN через WebSocket (маскируется под HTTPS). Обходит DPI и блокировки VPN-протоколов.

## Архитектура

```
[Android WireGuard] → [127.0.0.1:51820] → [wstunnel client] → [WebSocket/TLS] → [Render.com] → [wstunnel server] → [WireGuard server] → [Интернет]
```

## Быстрый старт

### 1. Деплой на Render.com

1. Создай новый репозиторий на GitHub и залей туда файлы из этого архива
2. На [Render.com](https://render.com) создай **New → Web Service**
3. Подключи свой GitHub репозиторий
4. Укажи **Environment Variables**:
   - `WSTUNNEL_SECRET` — случайная строка минимум 32 символа (например, `xK9#mP2$vL7@nQ4&wR8*tY3^hJ6!bF1`)
   - `CLIENT_PUBLIC_KEY` — пока оставь пустым, заполним после шага 2
5. Нажми **Deploy**
6. После деплоя открой логи сервера — там будет **Server Public Key** и **PresharedKey**

### 2. Генерация клиентских ключей

#### На Android (Termux):
```bash
# Скачай архив на телефон и распакуй
# В Termux:
cd ~/wstunnel-wireguard
bash client-setup.sh wss://your-app-name.onrender.com your-secret-from-render
```

#### На Linux/Mac:
```bash
bash client-setup.sh wss://your-app-name.onrender.com your-secret-from-render
```

Скрипт сгенерирует:
- `client_publickey` — вставь в Render как `CLIENT_PUBLIC_KEY`
- `client_privatekey` — для конфига WireGuard
- `wireguard-config/wg-client.conf` — готовый конфиг
- `start-tunnel.sh` — скрипт запуска туннеля

### 3. Настройка WireGuard на Android

1. Установи приложение **WireGuard** из Google Play
2. Импортируй файл `wireguard-config/wg-client.conf`
3. **Важно:** в поле `Endpoint` должен быть `127.0.0.1:51820`

### 4. Запуск

1. Открой Termux
2. Запусти: `./start-tunnel.sh`
3. Открой WireGuard и включи туннель
4. Проверь IP: открой браузер и зайди на [2ip.ru](https://2ip.ru)

## Файлы

| Файл | Назначение |
|------|------------|
| `Dockerfile` | Образ для Render.com |
| `entrypoint.sh` | Скрипт запуска сервера |
| `docker-compose.yml` | Для локального тестирования |
| `client-setup.sh` | Генерация ключей и конфига клиента |
| `wireguard-client.conf` | Шаблон конфига WireGuard |

## Безопасность

- `WSTUNNEL_SECRET` — обязательно задай длинный случайный секрет
- `PresharedKey` — добавляет дополнительный уровень шифрования
- `--restrict-to` — wstunnel может подключаться только к localhost:51820

## Устранение неполадок

**Ошибка: "Cannot assign requested address"**
→ Убедись, что в WireGuard `Endpoint = 127.0.0.1:51820`, а не IP сервера

**Ошибка: "Handshake did not complete"**
→ Проверь, что `CLIENT_PUBLIC_KEY` на сервере совпадает с ключом клиента

**Render "засыпает"**
→ На бесплатном тарифе первое подключение может занять 30–60 секунд. Отправь HTTP-запрос на URL сервера, чтобы разбудить.

**wstunnel не запускается в Termux**
→ Убедись, что скачал бинарник для правильной архитектуры (`aarch64` для большинства Android)

## Лицензия

Используй на свой страх и риск. Убедись, что использование VPN не нарушает законодательство твоей страны.
