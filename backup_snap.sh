#!/bin/bash

ITEM="$1"           # e.g. "docuScans"
SOURCE_FOLDER="$2"  # e.g. "/share"
LOCAL_FOLDER="$3"   # e.g. "/share/btrfs-snapshots"
REMOTE_USER="$4"    # e.g. "ansible-agent"
REMOTE_SERVER="$5"  # e.g. "litserv"
REMOTE_FOLDER="$6"  # e.g. "/backup/nas-backup/btrfs-snapshots"

CREATE_SNAP="./create_snap.sh"
if [ ! -x "$CREATE_SNAP" ]
then
  echo "Cannot execute $CREATE_SNAP" >&2
  exit -1
fi

PARENT_SNAP="./parent_snap.sh"
if [ ! -x "$PARENT_SNAP" ]
then
  echo "Cannot execute $PARENT_SNAP" >&2
  exit -1
fi

TIMESTAMP=$("$CREATE_SNAP" "$ITEM" "$SOURCE_FOLDER" "$LOCAL_FOLDER")
if [ $? != 0 ]
then
  echo "Failed to create snapshot" >&2
  exit -1
fi

PARENT=$(./parent_snap.sh "$ITEM" "$LOCAL_FOLDER" "$REMOTE_USER" "$REMOTE_SERVER" "$REMOTE_FOLDER")
if [ $? != 0 ]
then
  echo "No common remote parent found, need to do a full sync"
  sudo btrfs send "${LOCAL_FOLDER}/${ITEM}/${ITEM}_${TIMESTAMP}" | ( ssh "${REMOTE_USER}@${REMOTE_SERVER}" sudo btrfs receive "${REMOTE_FOLDER}/${ITEM}" )
else
  echo "Do an incremental sync with common parent $PARENT"
  sudo btrfs send -p "${LOCAL_FOLDER}/${ITEM}/${PARENT}" "${LOCAL_FOLDER}/${ITEM}/${ITEM}_${TIMESTAMP}" | ( ssh "${REMOTE_USER}@${REMOTE_SERVER}" sudo btrfs receive "${REMOTE_FOLDER}/${ITEM}" )
fi
