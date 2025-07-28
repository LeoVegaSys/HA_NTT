#!/bin/bash

# Description:
# Script intended to manage server state
# In MASTER mode, 
# Crontab is enabled
# Database is moved to READ/WRITE mode
# In BACKUP mode, 
# Crontab is disabled
# Database is moved to READ ONLY mode
# Logging is enabled

source /etc/keepalived/simplus_hist_01_ha_conf.ini

echo "=====================================================================" >> "$KEEPALIVED_LOG"

#LOG="/tmp/nttka.log"
#exec >> "$LOG" 2>&1

export HOME=/root
#echo "HOME :" $HOME >> "$LOGFILE"

# No need to specify -u or -p — uses ~/.my.cnf
"$MYSQL_PATH" -e "SELECT NOW();"

CRON_TOGGLE="$KEEPALIVED_BASE_FOLDER"/"$CRON_TOGGLE_SCRIPT"

# Example: toggle super_read_only
STATE=$("$MYSQL_PATH" -N -B -e "SELECT @@GLOBAL.super_read_only;")

if [ "$1" == "0" ]; then        # MASTER

    echo $(date) "Turning super_read_only OFF" >> "$KEEPALIVED_LOG"
    "$MYSQL_PATH" -e "SET GLOBAL super_read_only = OFF;" &
    "$MYSQL_PATH" -e "SET GLOBAL read_only = OFF;" &

    # Start crontab processes
    echo $(date) "Turning CRONTAB ON" >> "$KEEPALIVED_LOG"
    sh "$CRON_TOGGLE" uncomment > /dev/null 2>&1 &

    wait
    echo $(date) "Successfully transitioned to MASTER" >> "$KEEPALIVED_LOG"
    exit 0

else                            # BACKUP

    echo $(date) "Turning super_read_only ON" >> "$KEEPALIVED_LOG"
    "$MYSQL_PATH" -e "SET GLOBAL super_read_only = ON;" &

    # Stop crontab processes
    echo $(date) "Turning CRONTAB OFF" >> "$KEEPALIVED_LOG"
    sh "$CRON_TOGGLE" comment > /dev/null 2>&1 &

    wait
    echo $(date) "Successfully transitioned to BACKUP" >> "$KEEPALIVED_LOG"
    exit 0

fi