#!/bin/bash

# Установка Node.js и npm
echo "Устанавливаем Node.js и npm..."
sudo apt update
sudo apt install -y nodejs npm

# Инициализация нового проекта
echo "Инициализация проекта Node.js..."
npm init -y

# Установка ws и pm2
echo "Устанавливаем ws и pm2..."
npm install ws
sudo npm install -g pm2

# Создание файла server.js
echo "Создаем файл server.js..."
cat > server.js <<EOL
const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080, path: '/ping' });

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
EOL

# Запуск server.js через PM2
echo "Запуск server.js через PM2..."
pm2 start server.js

# Сохранение PM2 процесса для автозапуска
pm2 save

echo "Скрипт завершен!"
