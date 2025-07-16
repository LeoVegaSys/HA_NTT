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

LOGFILE="/var/log/ntt_keepalived.log"
echo "=====================================================================" >> "$LOGFILE"

#LOG="/tmp/nttka.log"
#exec >> "$LOG" 2>&1

export HOME=/root
#echo "HOME :" $HOME >> "$LOGFILE"

# No need to specify -u or -p — uses ~/.my.cnf
/usr/local/mysql/bin/mysql -e "SELECT NOW();" 

SCRIPT_DIR="/home/vegyan/VEGAYAN_NMS/MPLSWS_v2_3_29june"
#SCRIPT_NAME="test_longrunning_script.sh"
SCRIPT_NAME="simplus_stats_run.sh"
SCRIPT_PROCESS="simplus_stats.bin"

ON_NAME="$SCRIPT_DIR/spStatscommand.txt"
OFF_NAME="$SCRIPT_DIR/spStatscommand.txt.1"

CRON_TOGGLE="/etc/keepalived/toggle_cron.sh"

MAILER="/etc/keepalived/send_mail_1.py"

# Example: toggle super_read_only
STATE=$(/usr/local/mysql/bin/mysql -N -B -e "SELECT @@GLOBAL.super_read_only;")

# Get the PID using pgrep (searches for script name)
PID=$(pgrep -f "$SCRIPT_PROCESS")

if [ "$1" == "0" ]; then        # MASTER mode
#if [ "$1" == "1" ]; then        # BACKUP mode -- only for testing

    echo $(date) "MST :: Turning super_read_only OFF" >> "$LOGFILE"
#    /usr/local/mysql/bin/mysql -e "SET GLOBAL super_read_only = OFF;" &
    /usr/local/mysql/bin/mysql -e "SET GLOBAL super_read_only = ON;" &  # For testing purposes
    
    echo $(date) "MST :: Sleeping 2 in MASTER mode" >> "$LOGFILE"
    sleep 2s

    # Rename trigger script, to initiate polling
    echo $(date) "MST :: Renaming trigger file" >> "$LOGFILE"
#    mv "$OFF_NAME" "$ON_NAME"

    # Start crontab processes 
    echo $(date) "MST :: Turning CRONTAB ON" >> "$LOGFILE"
#    nohup sh "$CRON_TOGGLE" uncomment > /dev/null 2>&1 &
    
    exit 0

else                            # BACKUP mode

    # Rename trigger script, to block polling
    echo $(date) "BKP :: Renaming trigger file" >> "$LOGFILE"
#    mv "$ON_NAME" "$OFF_NAME"

    echo $(date) "BKP :: Turning super_read_only ON" >> "$LOGFILE"
#    /usr/local/mysql/bin/mysql -e "SET GLOBAL super_read_only = ON;" &

    echo $(date) "BKP :: Sleeping 1 in BACKUP mode" >> "$LOGFILE"
    sleep 1s

    # Stop crontab processes 
    echo $(date) "BKP :: Turning CRONTAB OFF" >> "$LOGFILE"
#    nohup sh "$CRON_TOGGLE" comment > /dev/null 2>&1 &
    
    # Kill any processes here
    if [ -n "$PID" ]; then
        echo $(date) "BKP :: Killing " $SCRIPT_NAME " process PID : " $PID >> "$LOGFILE"
        kill -9 $PID
    fi

    echo $(date) "BKP :: Sleeping 5 in BACKUP mode" >> "$LOGFILE"
    sleep 5s

    # Restart process
    echo $(date) "BKP :: Turning " $SCRIPT_NAME " ON" >> "$LOGFILE"
    # Change folder to script folder
    cd "$SCRIPT_DIR" || { echo "BKP :: ❌ Could not cd into $SCRIPT_DIR" >> "$LOGFILE" ; exit 1; }
    nohup sh "$SCRIPT_NAME" > /dev/null 2>&1 & >> "$LOGFILE"
    echo $(date) "BKP :: New " $SCRIPT_NAME " PID : " $! >> "$LOGFILE"

    exit 0

fi