#!/bin/bash

# Установка Certbot и зависимостей для SSL
echo "Устанавливаем Certbot для SSL..."
sudo apt install -y certbot

# Получаем IP-адрес сервера
SERVER_IP=$(hostname -I | awk '{print $1}')

# Сопоставление IP-адресов с доменами
declare -A ipToDomainMap=(
    ["95.164.69.17"]="unitedkingdoms.blackvpn.su"
    ["213.159.64.200"]="germania.blackvpn.su"
    ["185.156.108.14"]="finlands.blackvpn.su"
    ["85.209.153.153"]="netherlands.blackvpn.su"
    ["45.84.1.2"]="russia.blackvpn.su"
    ["45.89.53.23"]="usa.blackvpn.su"
    ["95.164.1.28"]="austria.blackvpn.su"
    ["5.180.45.193"]="turkey.blackvpn.su"
    ["86.104.74.103"]="france.blackvpn.su"
    ["45.159.250.35"]="kazahstan.blackvpn.su"
    ["194.54.159.14"]="netherlands-test.blackvpn.su"
    ["194.156.99.148"]="gonkong.blackvpn.su"
    ["91.194.11.144"]="canada.blackvpn.su"
    ["45.142.213.134"]="latvia.blackvpn.su"
    ["45.67.229.153"]="moldova.blackvpn.su"
    ["5.180.55.213"]="slovakia.blackvpn.su"
    ["45.14.246.249"]="ukraina.blackvpn.su"
    ["45.83.130.147"]="chehiya.blackvpn.su"
    ["95.164.0.157"]="polsha.blackvpn.su"
    ["146.19.80.23"]="bolgarka.blackvpn.su"
    ["94.131.119.238"]="romania.blackvpn.su"
    ["86.104.75.241"]="vengria.blackvpn.su"
    ["194.165.59.118"]="italia.blackvpn.su"
    ["45.83.142.206"]="portugalia.blackvpn.su"
    ["95.164.33.216"]="sweden.blackvpn.su"
    ["94.232.246.252"]="switzerland.blackvpn.su"
    ["2.56.172.216"]="serbia.blackvpn.su"
    ["194.4.48.42"]="spain.blackvpn.su"
    ["185.242.84.182"]="greece.blackvpn.su"
    ["94.131.14.96"]="lithuania.blackvpn.su"
    ["95.164.118.50"]="estonia.blackvpn.su"
    ["95.164.10.174"]="denmark.blackvpn.su"
    ["95.164.38.63"]="norway.blackvpn.su"
    ["45.83.20.39"]="belgium.blackvpn.su"
    ["45.83.21.107"]="iceland.blackvpn.su"
    ["5.253.41.83"]="japan.blackvpn.su"
    ["45.83.131.27"]="slovenia.blackvpn.su"
    ["45.83.143.117"]="armenia.blackvpn.su"
)

# Определяем домен на основе IP-адреса сервера
DOMAIN=${ipToDomainMap[$SERVER_IP]}

if [ -z "$DOMAIN" ]; then
    echo "Домен для IP $SERVER_IP не найден. Завершение работы."
    exit 1
fi

echo "Установленный домен: $DOMAIN"

# Получение SSL-сертификата от Let's Encrypt с использованием Certbot
sudo certbot certonly --standalone --preferred-challenges http -d $DOMAIN --register-unsafely-without-email --agree-tos

# Объявляем пути к SSL-сертификатам
SSL_CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

cd /ping

# Создание WebSocket-сервера с SSL и автоматическим выбором домена по IP
cat > server.js <<EOL
const fs = require('fs');
const https = require('https');
const WebSocket = require('ws');

// Создаем HTTPS-сервер с использованием SSL-сертификата
const server = https.createServer({
    cert: fs.readFileSync('$SSL_CERT'),
    key: fs.readFileSync('$SSL_KEY')
});

// Инициализируем WebSocket на HTTPS-сервере
const wss = new WebSocket.Server({ server, path: '/ping' });

wss.on('connection', function connection(ws) {
    console.log('Новое соединение установлено');

    ws.on('message', function incoming(message) {
        let ответ;
        if (typeof message === 'string') {
            ответ = message;
        } else if (message instanceof Buffer) {
            ответ = message.toString('utf8');
        } else {
            console.error('Неизвестный тип сообщения:', typeof message);
            return;
        }

        ws.send(ответ);
    });

    ws.on('close', function() {
        console.log('Соединение закрыто');
    });

    ws.on('error', function(error) {
        console.error('Ошибка WebSocket сервера:', error);
    });
});

// Запускаем сервер на порту 1488
server.listen(1488, () => {
    console.log('WebSocket сервер с SSL запущен на порту 1488');
});
EOL

# Запуск server.js через PM2
echo "Запуск server.js через PM2..."
pm2 restart server.js

# Автоматическое обновление SSL-сертификата
echo "Настройка автоматического обновления SSL-сертификата..."
(crontab -l 2>/dev/null; echo "0 0 * * 0 /usr/bin/certbot renew --post-hook 'pm2 restart server'") | crontab -

echo "Скрипт завершен!"
