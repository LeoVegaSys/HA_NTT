#!/bin/bash
# Purpose: Intended to correct MySQL read_only and super_read_only values
#          based on keepalived state
#          Checks every interval seconds
#          Invoked by Keepalived vrrp check script
# Properties :  VIP             : Keepalived Virtual IP
#               has_vip         : yes (MASTER) / Nn (BACKUP)
#               read_only       : MySQL read_only variable value
#               super_read_only : MySQL super_read_only variable value


PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

VIP="10.10.5.14"
MYSQL="/usr/local/mysql/bin/mysql"
IP="/usr/sbin/ip"
GET_LOCAL_SQL_CONF="--defaults-file=/etc/keepalived/mysql.cnf"

LOGFILE="/var/log/mysql_role_check.log"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Function to set read_only and super_read_only
set_read_only_vars() {
    local new_setting="$4"
    echo "$TIMESTAMP - STATE: NOT OKAY - VIP: $1, read_only: $2, super_read_only: $3" >> "$LOGFILE"
    "$MYSQL" "$GET_LOCAL_SQL_CONF" -e "SET GLOBAL super_read_only = $new_setting;"
    "$MYSQL" "$GET_LOCAL_SQL_CONF" -e "SET GLOBAL read_only = $new_setting;"
}

# Check VIP presence
has_vip=$("$IP" a | grep -q "$VIP" && echo "yes" || echo "no")

# Get current MySQL read states
read_only=$("$MYSQL" "$GET_LOCAL_SQL_CONF" -Nse "SELECT @@global.read_only;")
super_read_only=$("$MYSQL" "$GET_LOCAL_SQL_CONF" -Nse "SELECT @@global.super_read_only;")

# Main logic
if [ "$has_vip" == "yes" ]; then                                                #MASTER
    echo "State: MASTER"
    if [ "$read_only" == "1" ] || [ "$super_read_only" == "1" ]; then
        set_read_only_vars "$has_vip" "$read_only" "$super_read_only" "OFF"
    fi
else                                                                            #BACKUP
    echo "State: SLAVE"
    if [ "$read_only" == "0" ] || [ "$super_read_only" == "0" ]; then
        set_read_only_vars "$has_vip" "$read_only" "$super_read_only" "ON"
    fi
fi