#!/bin/bash

LOG_FILE="/var/log/monitoring.log"
STATE_FILE="/var/run/monitor_test.state"
PROCESS_NAME="test"
MONITOR_URL="https://test.com/monitoring/test/api"

# Проверка состояния процесса
if pgrep -x "$PROCESS_NAME" >/dev/null; then
  CURRENT_STATE="running"
else
  CURRENT_STATE="stopped"
fi

# Чтение предыдущего состояния
if [[ -f "$STATE_FILE" ]]; then
  PREVIOUS_STATE=$(cat "$STATE_FILE")
else
  PREVIOUS_STATE="unknown"
fi

# Логирование изменений состояния
if [[ "$CURRENT_STATE" != "$PREVIOUS_STATE" ]]; then
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Process $PROCESS_NAME changed state: $PREVIOUS_STATE -> $CURRENT_STATE" >> "$LOG_FILE"
fi

# Отправка запроса при работающем процессе
if [[ "$CURRENT_STATE" == "running" ]]; then
  curl_output=$(curl -sS -k -L -o /dev/null -w "%{http_code}" --max-time 5 "$MONITOR_URL" 2>&1)
  curl_exit=$?
  
  if [[ $curl_exit -ne 0 || "$curl_output" != "200" ]]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Monitoring server unreachable (Curl exit: $curl_exit, HTTP: $curl_output)" >> "$LOG_FILE"
  fi
fi

# Сохранение текущего состояния
echo "$CURRENT_STATE" > "$STATE_FILE"
