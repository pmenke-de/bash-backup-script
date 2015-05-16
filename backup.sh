#!/bin/bash
# Copyright (c) 2015 Philipp Menke
# Please refer the attached LICENSE file
# for license conditions.

SOURCE=$1
TARGET=$2
LEVEL=$3

if [ "X$LEVEL" = "X" ]; then
	LEVEL=0;
fi

EXIT_CODE=0
BACKUP_TIME=`date +%F`
TEMPDIR=$TARGET/tmp

LEVEL_OK=false
while [ $LEVEL_OK != "true" ]; do
	if [ $LEVEL -ne 0 ]; then
		PREV_LEVEL=$(($LEVEL - 1))
	else
		PREV_LEVEL=0
	fi

	BACKUP_PREFIX="level-$LEVEL-backup-"
	PREV_BACKUP_PREFIX="level-$PREV_LEVEL-backup-"

	SEQ=0
	while : ; do
		STATE_FILE=$BACKUP_PREFIX$BACKUP_TIME-$SEQ.state
		TGZ_FILE=$BACKUP_PREFIX$BACKUP_TIME-$SEQ.tgz
		if [ -f $TARGET/$TGZ_FILE ]; then
			SEQ=$(( SEQ + 1 ))
		else
			break
		fi
	done

	LAST_BACKUP=`find $TARGET -maxdepth 1 -type f -name "$PREV_BACKUP_PREFIX*" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]+" | sort -rVt "-" | head -n 1`
	if [ "X$LAST_BACKUP" = "X" ]; then
		LAST_BACKUP=never
	fi
	echo "Last level $PREV_LEVEL backup was \"$LAST_BACKUP\""

	if [ $LAST_BACKUP = never ] && [ $LEVEL -ne 0 ]; then
		echo "This is not allowed for all backup-levels except zero. Decrementing level!"
		LEVEL=$PREV_LEVEL
	else
		LEVEL_OK=true
	fi
done

echo -n "Creating new level $LEVEL backup of \"$SOURCE\" "
if [ $LEVEL -ne 0 ]; then
	echo "based on $PREV_BACKUP_PREFIX$LAST_BACKUP"
else
	echo
fi

mkdir -p $TEMPDIR || EXIT_CODE=1

if [ $LEVEL -ne 0 ]; then
	PREV_STATE_FILE=$PREV_BACKUP_PREFIX$LAST_BACKUP.state
	cp $TARGET/$PREV_STATE_FILE $TEMPDIR/$STATE_FILE || EXIT_CODE=2
fi

tar -cvzf $TEMPDIR/$TGZ_FILE -g $TEMPDIR/$STATE_FILE $SOURCE || EXIT_CODE=3

mv $TEMPDIR/$TGZ_FILE   $TARGET/$TGZ_FILE   || EXIT_CODE=4
mv $TEMPDIR/$STATE_FILE $TARGET/$STATE_FILE || EXIT_CODE=5

if [ $EXIT_CODE -eq 0 ]; then
	echo "Backup completed and saved to $TARGET/$BACKUP_PREFIX$BACKUP_TIME-$SEQ"
else
	echo "Backup failed. Please have a look at the log above."
	exit $EXIT_CODE
fi

