#!/usr/bin/python

import smtplib
import sys
import re
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
import argparse

config = {}

with open("/etc/keepalived/simplus_hist_01_ha_conf.ini") as f:
    for line in f:
        line = line.strip()
        if line.startswith("#") or not line:
            continue
        if "=" in line:
            key, value = line.split("=", 1)
            config[key.strip()] = value.strip().strip('"').strip("'")

smtp_server = config['SMTP_SERVER'] 
smtp_port = int(config['SMTP_PORT']) # Typically 587 for TLS
smtp_user = config['SMTP_USER'] 
smtp_pass = config['SMTP_PASS']

parser = argparse.ArgumentParser()
parser.add_argument('--subject', required=True, help='Email subject')
parser.add_argument('--body', required=True, help='Email body')

args = parser.parse_args()

sender_email=config['SENDER_EMAIL'] 
body = args.body 
message = MIMEText(body)
message['Subject'] = args.subject 
message['From'] = sender_email
message['To'] = config['RECEIVER_EMAIL'] 
receiver_emails = config['RECEIVER_EMAIL'].split(',')

try:
    with smtplib.SMTP(smtp_server, smtp_port, timeout=30) as server:
        server.starttls()  # Upgrade connection to secure TLS
        server.login(smtp_user, smtp_pass)
        #server.send_message(msg)
        server.sendmail(sender_email,receiver_emails, message.as_string())
        print("Email sent successfully!")
except Exception as e:
    print(f"Failed to send email: {e}")