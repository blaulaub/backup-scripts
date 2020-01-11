#!/bin/bash

LABEL="${1}"          # e.g. "white-dwarf.patchcode.ch"
SOURCE_FOLDER="${2}"  # e.g. "/share"
LOCAL_FOLDER="${3}"   # e.g. "/share/btrfs-backup"
REMOTE_USER="${4}"    # e.g. "ansible-agent"
REMOTE_SERVER="${5}"  # e.g. "white-dwarf"
REMOTE_VOLUME="${6}"  # e.g. "/"
REMOTE_FOLDER="${7}"  # e.g. "/backup" (on $REMOTE_SERVER)
FINAL_USER="${8}"     # e.g. "ansible-agent"
FINAL_SERVER="${9}"   # e.g. "litserv"
FINAL_FOLDER="${10}"  # e.g. "/backup/btrfs-backup" (on litserv)

CREATE_RSNAP="./create_rsnap.sh"
if [ ! -x "$CREATE_RSNAP" ]
then
  echo "Cannot execute $CREATE_RSNAP" >&2
  exit -1
fi

PARENT_SNAP="./parent_snap.sh"
if [ ! -x "$PARENT_SNAP" ]
then
  echo "Cannot execute $PARENT_SNAP" >&2
  exit -1
fi

ssh "${REMOTE_USER}@${REMOTE_SERVER}" sudo sync

TIMESTAMP=$("$CREATE_RSNAP" "$REMOTE_USER" "$REMOTE_SERVER" "$LABEL" "$REMOTE_VOLUME" "$REMOTE_FOLDER")
if [ $? != 0 ]
then
  echo "Failed to create snapshot" >&2
  exit -1
fi

ssh "${REMOTE_USER}@${REMOTE_SERVER}" sudo sync

PARENT1=$(./parent_snap.sh "$LABEL" "$LOCAL_FOLDER" "$REMOTE_USER" "$REMOTE_SERVER" "$REMOTE_FOLDER")
if [ $? != 0 ]
then
  echo "No common remote parent found, need to do a full sync"
  ( ssh "${REMOTE_USER}@${REMOTE_SERVER}" sudo btrfs send "${REMOTE_FOLDER}/${LABEL}/${LABEL}_${TIMESTAMP}" ) | sudo btrfs receive "${LOCAL_FOLDER}/${LABEL}/"
else
  echo "Do an incremental sync with common parent $PARENT1"
  ( ssh "${REMOTE_USER}@${REMOTE_SERVER}" sudo btrfs send -p "${REMOTE_FOLDER}/${LABEL}/${PARENT1}" "${REMOTE_FOLDER}/${LABEL}/${LABEL}_${TIMESTAMP}" ) | sudo btrfs receive "${LOCAL_FOLDER}/${LABEL}/"
fi

sudo sync

PARENT2=$(./parent_snap.sh "$LABEL" "$LOCAL_FOLDER" "$FINAL_USER"  "$FINAL_SERVER" "$FINAL_FOLDER")
if [ $? != 0 ]
then
  echo "No common remote parent found, need to do a full sync"
  sudo btrfs send "${LOCAL_FOLDER}/${LABEL}/${LABEL}_${TIMESTAMP}" | ( ssh "${FINAL_USER}@${FINAL_SERVER}" sudo btrfs receive "${FINAL_FOLDER}/${LABEL}" )
else
  echo "Do an incremental sync with common parent $PARENT2"
  sudo btrfs send -p "${LOCAL_FOLDER}/${LABEL}/${PARENT2}" "${LOCAL_FOLDER}/${LABEL}/${LABEL}_${TIMESTAMP}" | ( ssh "${FINAL_USER}@${FINAL_SERVER}" sudo btrfs receive "${FINAL_FOLDER}/${LABEL}" )
fi



