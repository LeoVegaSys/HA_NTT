#!/bin/bash

# Description:
# Script is intended to maintain backup of latest crontab as well as 
# allow activating/deactivating crontab commands, based on server 
# state ( MASTER/BACKUP) [defined in toggle_sro_m.sh]
# Logging is enabled
# Usage : sh toggle_cron.sh [comment/uncomment]
# Backup is stored on /etc/keepalived/ folder

LOGFILE="/var/log/ntt_keepalived.log"
BASE="/etc/keepalived"
BKP="$BASE"/mycron.bak
TMP="$BASE"/mycron.tmp
ACTION=$1  # Expected values: "comment" or "uncomment"

if [[ "$ACTION" != "comment" && "$ACTION" != "uncomment" ]]; then
  echo "Usage: $0 {comment|uncomment}"
  exit 1
fi

# Backup existing crontab
crontab -l > "$BKP" 2>/dev/null || touch "$BKP"
echo "Existing crontab copied to " $BKP >> "$LOGFILE"
crontab -l >> "$LOGFILE"
echo >> "$LOGFILE"

cp "$BKP" "$TMP"

if [[ "$ACTION" == "comment" ]]; then
  # Add '#' at beginning of each non-comment, non-empty line
  sed -i -E '/^[ \t]*[0-9\*]/ s/^/#/' "$TMP"
elif [[ "$ACTION" == "uncomment" ]]; then
  # Remove '#' from beginning of lines (if present)
  sed -i -E '/^#[ \t]*[0-9\*]/ s/^#//' "$TMP"
fi

# Install the modified crontab
crontab "$TMP"
rm "$TMP"

echo "All cron jobs have been ${ACTION}ed." >> "$LOGFILE"
crontab -l >> "$LOGFILE"
echo >> "$LOGFILE"