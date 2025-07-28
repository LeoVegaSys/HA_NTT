#!/bin/bash

# Description:
## Script intended to manage server state
# In MASTER mode,
## Crontab is enabled
## Database is moved to READ/WRITE mode
## Rename trigger file to enable polling
# In BACKUP mode,
## Crontab is disabled
## Database is moved to READ ONLY mode
## Rename trigger file to disable polling
## Restart Simplus service
# Logging is enabled

source /etc/keepalived/simplus_auto_02_ha_conf.ini

echo "=====================================================================" >> "$KEEPALIVED_LOG"

#LOG="/tmp/nttka.log"
#exec >> "$LOG" 2>&1

export HOME=/root
#echo "HOME :" $HOME >> "$LOGFILE"

# No need to specify -u or -p — uses ~/.my.cnf
"$MYSQL_PATH" -e "SELECT NOW();" 

ON_NAME="$SIMPLUS_WS_PATH/$SIMPLUS_TRIGGER_POLLING_ON"
OFF_NAME="$SIMPLUS_WS_PATH/$SIMPLUS_TRIGGER_POLLING_OFF"

#CRON_TOGGLE="/etc/keepalived/toggle_cron.sh"
CRON_TOGGLE="$KEEPALIVED_BASE_FOLDER"/"$CRON_TOGGLE_SCRIPT"

# Example: toggle super_read_only
STATE=$("$MYSQL_PATH" -N -B -e "SELECT @@GLOBAL.super_read_only;")

# Get the PID using pgrep (searches for script name)
PID=$(pgrep -f "$SIMPLUS_PROC_IDENTIFIER")

if [ "$1" == "0" ]; then        # MASTER mode

    echo $(date) "MST :: Turning super_read_only OFF" >> "$KEEPALIVED_LOG"
    "$MYSQL_PATH" -e "SET GLOBAL super_read_only = OFF;" &
    "$MYSQL_PATH" -e "SET GLOBAL read_only = OFF;" &
    
    echo $(date) "MST :: Sleeping 2 in MASTER mode" >> "$KEEPALIVED_LOG"
    sleep 2s

    # Rename trigger script, to initiate polling
    echo $(date) "MST :: Renaming trigger file" >> "$KEEPALIVED_LOG"
    mv "$OFF_NAME" "$ON_NAME"

    # Start crontab processes 
    echo $(date) "MST :: Turning CRONTAB ON" >> "$KEEPALIVED_LOG"
    sh "$CRON_TOGGLE" uncomment > /dev/null 2>&1 &
   
    wait
    echo $(date) "Successfully transitioned to MASTER" >> "$KEEPALIVED_LOG"
    exit 0

else                            # BACKUP mode

    # Rename trigger script, to block polling
    echo $(date) "BKP :: Renaming trigger file" >> "$KEEPALIVED_LOG"
    mv "$ON_NAME" "$OFF_NAME"

    echo $(date) "BKP :: Turning super_read_only ON" >> "$KEEPALIVED_LOG"
    "$MYSQL_PATH" -e "SET GLOBAL super_read_only = ON;" &

    echo $(date) "BKP :: Sleeping 1 in BACKUP mode" >> "$KEEPALIVED_LOG"
    sleep 1s

    # Stop crontab processes 
    echo $(date) "BKP :: Turning CRONTAB OFF" >> "$KEEPALIVED_LOG"
    sh "$CRON_TOGGLE" comment > /dev/null 2>&1 &
    
    # Kill any processes here
    if [ -n "$PID" ]; then
        echo $(date) "BKP :: Killing $SIMPLUS_SCRIPT process PID : " $PID >> "$KEEPALIVED_LOG"
        kill -9 $PID
    fi

    echo $(date) "BKP :: Sleeping 5 in BACKUP mode" >> "$KEEPALIVED_LOG"
    sleep 5s

    # Restart process
    echo $(date) "BKP :: Turning $SIMPLUS_SCRIPT ON" >> "$KEEPALIVED_LOG"
    # Change folder to script folder
    cd "$SIMPLUS_WS_PATH" || { echo "BKP :: Could not cd into $SIMPLUS_WS_PATH" >> "$KEEPALIVED_LOG" ; exit 1; }
    nohup sh "$SIMPLUS_SCRIPT" > /dev/null 2>&1 & >> "$KEEPALIVED_LOG"
    echo $(date) "BKP :: New $SIMPLUS_SCRIPT PID : " $! >> "$KEEPALIVED_LOG"

    wait
    echo $(date) "Successfully transitioned to BACKUP" >> "$KEEPALIVED_LOG"
    exit 0

fi