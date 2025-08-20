#!/usr/bin/env python3
"""
Purpose: Backup older binlogs by compressing and safely purging them.
"""

import os
import sys
import zipfile
import subprocess
from datetime import datetime, timedelta

# --- Load config manually ---
CONFIG_PATH = "/etc/keepalived/simplus_hist_01_ha_conf.ini"
#CONFIG_PATH = "/home/vegyan/tst/conf.ini"
config = {}

with open(CONFIG_PATH) as f:
    for line in f:
        line = line.strip()
        if line.startswith("#") or not line:
            continue
        if "=" in line:
            key, value = line.split("=", 1)
            config[key.strip()] = value.strip().strip('"').strip("'")

# --- Required keys ---
required_keys = [
    "BINLOG_DIR",
    "BACKUP_DIR",
    "KEEP_LAST",
    "KEEP_LAST_N_DAYS",
    "LOCAL_MYSQL_CRED_CONF",
    "BINLOG_PREFIX",
]
missing = [k for k in required_keys if k not in config]
if missing:
    print(f"Error: Missing config keys: {', '.join(missing)}")
    sys.exit(1)

BINLOG_DIR = config["BINLOG_DIR"]
BACKUP_DIR = config["BACKUP_DIR"]
KEEP_LAST = int(config["KEEP_LAST"])
KEEP_LAST_N = int(config["KEEP_LAST_N_DAYS"])
LOCAL_MYSQL_CRED_CONF = os.path.expanduser(config["LOCAL_MYSQL_CRED_CONF"])
BINLOG_PREFIX = config["BINLOG_PREFIX"]

print(f"Keep logs of last {KEEP_LAST_N} days, including latest {KEEP_LAST} logs")

# --- Flags ---
DRY_RUN = "--dry-run" in sys.argv
NO_PURGE = "--no-purge" in sys.argv

os.makedirs(BACKUP_DIR, exist_ok=True)

# --- Get current binlog ---
#cmd = ["mysql", f"--defaults-file={LOCAL_MYSQL_CRED_CONF}", "-N", "-s", "-e", "SHOW MASTER STATUS;"]
cmd = ["/usr/local/mysql/bin/mysql", f"--defaults-file={LOCAL_MYSQL_CRED_CONF}", "-N", "-s", "-e", "SHOW MASTER STATUS;"]
output = subprocess.check_output(cmd, universal_newlines=True).strip()
if not output:
    print("No binlog info from MySQL, exiting.")
    sys.exit(0)

current_binlog = output.split()[0]
print(f"Current binlog from MySQL: {current_binlog}")

# --- List binlogs ---
files = [
    f for f in os.listdir(BINLOG_DIR)
    if f.startswith(BINLOG_PREFIX + ".") and not f.endswith(".index")
]
if not files:
    print("No binlogs found.")
    sys.exit(0)

# Sort binlogs numerically
files.sort(key=lambda x: int(x.split(".")[-1]))

# Filter only binlogs <= current_binlog
files = [f for f in files if int(f.split(".")[-1]) <= int(current_binlog.split(".")[-1])]

# Determine binlogs to keep by count
to_keep_by_count = files[-KEEP_LAST:]
print(f"Keep by count : {to_keep_by_count}")

# Determine binlogs to keep by date
now = datetime.now()
keep_by_date = []
for f in files:
    path = os.path.join(BINLOG_DIR, f)
    mtime = datetime.fromtimestamp(os.path.getmtime(path))
    if (now - mtime).days <= KEEP_LAST_N:
        keep_by_date.append(f)
print(f"Keep by date  : {keep_by_date}")

# Final set of files to keep
keep_set = set(to_keep_by_count)
keep_set.add(current_binlog)
keep_set.update(keep_by_date)

# Files to purge/archive
to_purge = [f for f in files if f not in keep_set]

print(f"Keeping: {', '.join(sorted(keep_set))}")
print(f"Archiving: {', '.join(to_purge) if to_purge else 'None'}")

if DRY_RUN or not to_purge:
    print("Dry run: no files touched.")
    sys.exit(0)

# --- Archive and purge ---
for f in to_purge:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    zip_path = os.path.join(BACKUP_DIR, f"{f}_{ts}.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(os.path.join(BINLOG_DIR, f), arcname=f)
    print(f"Archived {f} -> {zip_path}")

# Purge via MySQL command
if not NO_PURGE and to_purge:
    last_to_purge = sorted(to_purge)[-1]
    purge_cmd = [
        #"mysql",
        "/usr/local/mysql/bin/mysql",
        f"--defaults-file={LOCAL_MYSQL_CRED_CONF}",
        "-e",
        f"PURGE BINARY LOGS TO '{last_to_purge}';"
    ]
    subprocess.run(purge_cmd, check=True)
    print(f"Purged MySQL binary logs up to {last_to_purge}")

print("Done.")
