# HA_NTT

High Availibility (HA)
======================

The HA setup consists of 2 sections: Replication and Keepalived

Replication
===========

Replication is performed using MySQL database. The purpose being to make sure all servers in the replication structure hold the same data at any point in time.
Replication involves:
    - Configuring MySQL with replication-specific parameters                -- refer Replication_Configurations
    - Setting up Replication users and privileges                           -- refer NTT_OPS_replication_implementation.txt
    - Configuring replication relationships (MASTER-SLAVE or MASTER-MASTER) -- refer NTT_OPS_replication_implementation.txt
    - Initiating Replication data flow                                      -- refer NTT_OPS_replication_implementation.txt

Primary files involved:
    - my.cnf                                                                -- MySQL configuration file

States:
    - MASTER
    - SLAVE


Keepalived
==========
High Availability/Failover is performed using keepalived package. The purpose being to make sure atleast one server in the HA structure, is always accessible and functional.
High Availability involves:
    - Configuring keepalived                                                -- refer Keepalived_Configurations
    - Setting up monitoring scripts
    - Setting up notification scripts

Primary files involved:
    - keepalived.conf                                                       -- Keepalived configuration file
    - monitoring scripts
        - current setup includes check_service.sh/check_process.sh/check_mysql.sh script/s
        - Monitors the service/process, frequency set by keepalived configuration parameter `interval`
        - Should return 0 (if service is running) and 1 (if service is failed/down)
    - notification scripts
        - current setup includes state_change_primary.sh/state_change_secondary.sh/send_notify_mail.sh script/s
        - Performs startup (state change to MASTER) / cleanup (state change to BACKUP) actions on server keepalived state change
    - support scripts
        - toggle_cron.sh : Uncomment (state change to MASTER) / Comment (state change to BACKUP) crontab
        - send_ha_mail.py : generic emailing script
        - manage_mysql_read.sh  : monitors and modifies MySQL read_only parameters as per server state
        - binlog_purge.py : Handles backup and purge of old MySQL binlogs  
    - support configuration files
        - <server name>_ha_conf.ini : Holds all script-relevant parameters

States:
    - MASTER
    - BACKUP
    - FAULT