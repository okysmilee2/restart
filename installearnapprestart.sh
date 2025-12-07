cat << "EOF" > /usr/local/bin/earnapp-restart.sh
#!/bin/bash
BOT_TOKEN="7106813327:AAGGKiDStDXurmdBJU2TzSJ0s6jm7Ds9wxk"
CHAT_ID="702916090"
earnapp stop
sleep 15
earnapp start
curl -s -o /dev/null -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
     -d chat_id="${CHAT_ID}" \
     -d text="🔁 Auto Restart: $(hostname) OK ✓ pada $(date '+%H:%M:%S %d-%m-%Y')"
EOF

cat << "EOF" > /usr/local/bin/bot-handler.sh
#!/bin/bash
BOT_TOKEN="7106813327:AAGGKiDStDXurmdBJU2TzSJ0s6jm7Ds9wxk"
CHAT_ID="702916090"
HOST=$(hostname)
COMMAND_RESTART="/restart_${HOST}"
handle_message() {
    local message="$1"
    if [[ "$message" == "$COMMAND_RESTART" ]]; then
        earnapp stop
        sleep 15
        earnapp start
        curl -s -o /dev/null -X POST \
        "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="✔ Restart EarnApp di ${HOST} sukses! ⏱ $(date '+%H:%M:%S %d-%m-%Y')"
    fi
}
LAST_UPDATE_ID=0
while true; do
    UPDATES=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?offset=${LAST_UPDATE_ID}")
    MESSAGE=$(echo "$UPDATES" | grep -oP '"text":"\K[^"]+')
    UPDATE_ID=$(echo "$UPDATES" | grep -oP '"update_id":\K[0-9]+' | tail -1)
    if [[ ! -z "$UPDATE_ID" ]]; then
        LAST_UPDATE_ID=$((UPDATE_ID+1))
        handle_message "$MESSAGE"
    fi
    sleep 3
done
EOF

chmod +x /usr/local/bin/earnapp-restart.sh
chmod +x /usr/local/bin/bot-handler.sh

(crontab -l 2>/dev/null; echo "0 */3 * * * /usr/local/bin/earnapp-restart.sh") | crontab -

echo "nohup /usr/local/bin/bot-handler.sh >/dev/null 2>&1 &" >> /etc/rc.local
chmod +x /etc/rc.local

nohup /usr/local/bin/bot-handler.sh >/dev/null 2>&1 &