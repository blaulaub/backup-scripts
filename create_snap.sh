#!/bin/bash

# Create BTRFS readonly snapshot.
#
# Execution:
#   create_snap.sh <item> <parent folder> <snapshot folder>
#
# Note:
#   - run as normal user with sudo privileges
#   - on success, returns a $TIMESTAMP code
#   - resulting snapshot name is:
#        <snapshot folder>/<item>_$TIMESTAMP

TIMESTAMP="$(date --utc '+%Y%m%dT%H%M%SZ')"

ITEM="$1"           # e.g. "docuScans"
SOURCE_FOLDER="$2"  # e.g. "/share"
TARGET_FOLDER="$3"  # e.g. "/share/btrfs-snapshots"

SOURCE="${SOURCE_FOLDER}/${ITEM}"
TARGET="${TARGET_FOLDER}/${ITEM}/${ITEM}_${TIMESTAMP}"

if [ ! -d "$SOURCE" ]
then
  echo "Source folder not found: $SOURCE" >&2
  exit -1
fi

if [ -d "$TARGET" ]
then
  echo "Target folder already exists: $TARGET" >&2
  exit -1
fi

if ! sudo btrfs --version >&2
then
  echo "Failed to run btrfs as sudo." >&2
  exit -1
fi

if ! sudo btrfs subvolume snapshot -r "${SOURCE}" "${TARGET}" >&2
then
  >&2 echo "Failed to create btrfs snapshot."
  exit -1
fi

echo "$TIMESTAMP"
