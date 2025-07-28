#!/usr/bin/python

from datetime import datetime
import smtplib
import sys
import re
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders

smtp_server = "smtp-us.ser.proofpoint.com"  # or "smtp-eu.ser.proofpoint.com"
smtp_port = 25  # Typically 587 for TLS
#smtp_port = 587
smtp_user = "5cc2e600-7cd3-4778-a7df-cb60449634f7"
smtp_pass = "1;?DqPkZz4,d"

host_ip = sys.argv[1] 
proc_name = sys.argv[2] 

#sender_email = "ap.in.nttmon-alert@global.com"
sender_email= "ap.in.nttmon-alert@nttdata.com"
#receiver_emails=['nttin.nttsupport@global.ntt','nttin.helpdesk@global.ntt','siddhesh_palav@vegayan.com','vaishnavi_bhokare@vegayan.com','sarvesh_pawar@vegayan.com']
#receiver_emails=['siddhesh_palav@vegayan.com','vaishnavi_bhokare@vegayan.com','sarvesh_pawar@vegayan.com']
receiver_emails=['lionel_almeida@vegayan.com','akash_mishra@vegayan.com','harsh_mishra@vegayan.com']
#message = MIMEMultipart('alternative')
body = f"Process {proc_name} has gone down on host {host_ip} at {datetime.now()}."
message = MIMEText(body)
#message['Subject'] = 'NTT-Vegayan NMS Critical Alarms'
message['Subject'] = f'Failure Alert: Process {proc_name} failed on {host_ip}'
#message['From'] = 'ap.in.nttmon-alert@nttdata.com'
#message['From'] = 'ap.in.nttmon-alert@global.com'
message['From'] = sender_email 
message['To'] = ', '.join(receiver_emails)

try:
    with smtplib.SMTP(smtp_server, smtp_port, timeout=30) as server:
        server.starttls()  # Upgrade connection to secure TLS
        server.login(smtp_user, smtp_pass)
        #server.send_message(msg)
        server.sendmail(sender_email,receiver_emails, message.as_string())
        print("Email sent successfully!")
except Exception as e:
    print(f"Failed to send email: {e}")