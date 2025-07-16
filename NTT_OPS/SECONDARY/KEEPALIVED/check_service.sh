#!/bin/bash

# Description: 
# Shell script intended to check for Simplus AND MySQL in processlist.
# Stores process IDs and checks for presence
# Returns 0 (denoting SUCCESS) only if both processes (SimPLUS and MySQL) are running.
# Otherwise returns 1 (denoting FAILURE)

KEYWORD="simplus_stats.bin"
#TOMCAT_KEYWORD="simplus_stats_run.sh"
#TOMCAT_KEYWORD="test_longrunning_script.sh"

MYSQL_PIDS=$(pidof mysqld)
SCRIPT_PIDS=$(pgrep -f "$KEYWORD")

# Check if the processes is running
#if pgrep -f "$TOMCAT_KEYWORD" > /dev/null; then
if  [[ -n "$MYSQL_PIDS" && -n "$SCRIPT_PIDS" ]]; then
    exit 0
else
    exit 1
fi