#!/usr/bin/env python3

'''
 Purpose : Backup older binlogs by compress and safe purge
 Properties :   BINLOG_DIR - bin log file source path
                BACKUP_DIR - bin log file backup destination path
                KEEP_LAST  - Number of latest binlogs to be skipped
 Usage : python binlog_purge.py --dry-run  # Returns activity stats
         python binlog_purge.py --no-purge # Backup to compressed file/s only
'''

import os, sys, zipfile, subprocess
from datetime import datetime

# --- Config ---
BINLOG_DIR = "/var/lib/mysql"                # adjust if needed
BACKUP_DIR = "/var/lib/mysql/binlog-archive" # where zips are stored
KEEP_LAST = 3

# --- Flags ---
DRY_RUN = "--dry-run" in sys.argv
NO_PURGE = "--no-purge" in sys.argv

os.makedirs(BACKUP_DIR, exist_ok=True)

# --- Get current binlog from MySQL ---
cmd = ["mysql", "--defaults-file=~/.my.cnf", "-N", "-s", "-e", "SHOW MASTER STATUS;"]
output = subprocess.check_output(cmd, universal_newlines=True).strip()
current_binlog = output.split()[0]
print(f"Current binlog from MySQL: {current_binlog}")

# --- List binlogs ---
files = [f for f in os.listdir(BINLOG_DIR) if f.startswith("mysql-bin.")]
if not files:
    print("No binlogs found.")
    sys.exit(0)

files.sort(key=lambda x: int(x.split(".")[-1]))
files = [f for f in files if int(f.split(".")[-1]) <= int(current_binlog.split(".")[-1])]

# --- Purge logic ---
to_keep = files[-KEEP_LAST:]
to_purge = files[:-KEEP_LAST]
print(f"Keeping: {', '.join(to_keep)}")
print(f"Archiving: {', '.join(to_purge) if to_purge else 'None'}")

if DRY_RUN or not to_purge:
    print("Dry run: no files touched.")
    sys.exit(0)

# --- Archive each file individually ---
for f in to_purge:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    zip_path = os.path.join(BACKUP_DIR, f"{f}_{ts}.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(os.path.join(BINLOG_DIR, f), arcname=f)
    print(f"Archived {f} -> {zip_path}")
    if not NO_PURGE:
        os.remove(os.path.join(BINLOG_DIR, f))
        print(f"Deleted {f}")

print("Done.")