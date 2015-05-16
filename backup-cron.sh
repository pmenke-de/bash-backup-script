#!/bin/bash
# Copyright (c) 2015 Philipp Menke
# Please refer the attached LICENSE file
# for license conditions.

if [ ! -d /var/backup/log ]; then mkdir -p /var/backup/log; fi
LOGFILE=log/backup-`date +"%F"`.log
exec >> /var/backup/$LOGFILE 2>&1

DOM=`date +"%d"`
DOW=`date +"%w"`
if [ $DOM = "01" ]; then
  #Create a full backup every first day of month
  LEVEL=0
elif [ $DOW = "0" ]; then
  #Create a backup based on the monthly one, on every sunday
  LEVEL=1
else 
  #Create a backup based on the weekly one, on every other invocation (daily)
  LEVEL=2
fi

cd /var/backup
./backup.sh /etc etc $LEVEL
./backup.sh manual-input manual $LEVEL

#Optionally push the updates via SFTP to you remote backup location
#lftp -e 'mirror --reverse -x '$LOGFILE' /var/backup/ /remote-backup-target/ ; exit' sftp://backup-server
#And also push the logs, when we're done
#scp $LOGFILE backup-server:/remote-backup-target/backup/log/ > /dev/null 2>&1
