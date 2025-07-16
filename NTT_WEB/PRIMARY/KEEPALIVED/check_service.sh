#!/bin/bash

# Description: 
# Shell script intended to check for Simplus Tomcat Web service in processlist.
# Returns 0 (denoting SUCCESS) only if process (Tomcat) is running.
# Otherwise returns 1 (denoting FAILURE)

# Customize this with your actual Tomcat process keyword
TOMCAT_KEYWORD="org.apache.catalina.startup.Bootstrap"
#TOMCAT_KEYWORD="test_longrunning_script.sh"
# Check if the process is running
if pgrep -f "$TOMCAT_KEYWORD" > /dev/null; then
    echo "Tomcat is running."
    exit 0
else
    echo "Tomcat is NOT running."
    exit 1
fi