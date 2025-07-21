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


LOGFILE="/var/log/ntt_keepalived.log"

echo >> "$LOGFILE"

#LOG="/tmp/nttka.log"
#exec >> "$LOG" 2>&1

export HOME=/root
#echo "HOME :" $HOME >> "$LOGFILE"

# No need to specify -u or -p — uses ~/.my.cnf
/usr/local/mysql/bin/mysql -e "SELECT NOW();"

CRON_TOGGLE="/etc/keepalived/toggle_cron.sh"

# Example: toggle super_read_only
STATE=$(/usr/local/mysql/bin/mysql -N -B -e "SELECT @@GLOBAL.super_read_only;")

if [ "$1" == "0" ]; then        # MASTER

    echo $(date) "Turning super_read_only OFF" >> "$LOGFILE"
#    /usr/local/mysql/bin/mysql -e "SET GLOBAL super_read_only = OFF;" &
#    /usr/local/mysql/bin/mysql -e "SET GLOBAL read_only = OFF;" &

    # Start crontab processes 
    echo $(date) "Turning CRONTAB ON" >> "$LOGFILE"
#    nohup sh "$CRON_TOGGLE" uncomment > /dev/null 2>&1 &
    exit 0

else                            # BACKUP

    echo $(date) "Turning super_read_only ON" >> "$LOGFILE"
#    /usr/local/mysql/bin/mysql -e "SET GLOBAL super_read_only = ON;" &

    # Stop crontab processes 
    echo $(date) "Turning CRONTAB OFF" >> "$LOGFILE"
#    nohup sh "$CRON_TOGGLE" comment > /dev/null 2>&1 &
    
    exit 0

fi