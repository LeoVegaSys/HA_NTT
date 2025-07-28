#!/bin/bash

source /etc/keepalived/simplus_hist_01_ha_conf.ini

body="Keepalived has changed state to $3 on host $HOST_IDENTIFIER $IP."
subject="HA Keepalived Notification : $HOST_IDENTIFIER $IP moved to $3 mode"

$PYTHON_PATH "$KEEPALIVED_BASE_FOLDER"/send_ha_mail.py --subject "$subject" --body "$body"

exit 0