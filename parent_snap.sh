#!/bin/bash

# Find latest common snapshot in local and remote folder, based on the snapshot name.
#
# Execution:
#   parent_snap.sh <item> <local folder> <remote user> <remote server> <remote folder>
#
# Note:
#   - run as normal user with sudo privileges
#   - on success, returns the snapshot name, usually <item>_$TIMESTAMP
#   - when no match is found, exits with non-zero return code

ITEM="$1"           # e.g. "docuScans"
LOCAL_FOLDER="$2"   # e.g. "/share/btrfs-snapshots"
REMOTE_USER="$3"    # e.g. "ansible-agent"
REMOTE_SERVER="$4"  # e.g. "litserv"
REMOTE_FOLDER="$5"  # e.g. "/backup/nas-backup/btrfs-snapshots"

if ! ssh "${REMOTE_USER}@${REMOTE_SERVER}" true >&2
then
  echo "Failed to connect to remote machine." >&2
  exit -1
fi

if ! ssh "${REMOTE_USER}@${REMOTE_SERVER}" sudo true >&2
then
  echo "Failed to run sudo on remote machine." >&2
  exit -1
fi

LOCAL_LIST=( $(sudo ls -1 "${LOCAL_FOLDER}/${ITEM}") )
if [ $? != 0 ]
then
  echo "Failed to list local snapshots." >&2
  exit -1
fi

REMOTE_LIST=( $(ssh "${REMOTE_USER}@${REMOTE_SERVER}" sudo ls -1 "${REMOTE_FOLDER}/${ITEM}") )
if [ $? != 0 ]
then
  echo "Failed to list remote snapshots." >&2
  exit -1
fi

PARENT=""
for LOCAL in "${LOCAL_LIST[@]}"
do
  for REMOTE in "${REMOTE_LIST[@]}"
  do
    if [ "$LOCAL" = "$REMOTE" ]
	then
	  PARENT="$LOCAL"
	fi
  done
done

if [ -z "$PARENT" ]
then
  echo "No remote snapshot found." >&2
  exit -1
fi

echo "$PARENT"