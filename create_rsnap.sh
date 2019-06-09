#!/bin/bash

# Create BTRFS readonly snapshot on remote machine.
#
# Execution:
#   create_rsnap.sh <user> <machine> <label> <volume> <snapshot folder>
#
# Note:
#   - run as normal user with sudo privileges
#   - on success, returns a $TIMESTAMP code
#   - resulting snapshot name is:
#        <snapshot folder>/<item>_$TIMESTAMP

TIMESTAMP="$(date --utc '+%Y%m%dT%H%M%SZ')"

REMOTE_USER="$1"    # e.g. "ansible-agent"
REMOTE_SERVER="$2"  # e.g. "white-dwarf"
LABEL="$3"          # e.g. "white-dwarf.patchcode.ch
SOURCE="$4"         # e.g. /
TARGET_FOLDER="$5"  # e.g. "/backup"

TARGET="${TARGET_FOLDER}/${LABEL}/${LABEL}_${TIMESTAMP}"


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

if ! ssh "${REMOTE_USER}@${REMOTE_SERVER}" sudo btrfs subvolume snapshot -r "${SOURCE}" "${TARGET}" >&2
then
  echo "Failed to create btrfs snapshot." >&2
  exit -1
fi

echo "$TIMESTAMP"
