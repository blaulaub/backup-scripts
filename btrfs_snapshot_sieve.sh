#!/bin/bash -e
if [ -z "$VOLUME" ]; then
	echo "VOLUME not set"
	exit -1
fi

if [ -z "$MULTIPLIER" ]; then
	echo "MULTIPLIER not set"
	exit -1
fi

NOW="$( date '+%s' )"
mapfile -t SNAPSHOTS < <( btrfs subvolume list "$VOLUME" | cut -d" " -f9 | egrep '_[0-9]{8}T[0-9]{6}Z$' | sort -r )
mapfile -t BASENAMES < <( for SNAPSHOT in "${SNAPSHOTS[@]}"; do echo $SNAPSHOT ; done | sed -e 's/_[0-9]\{8\}T[0-9]\{6\}Z$//' | sort -u )

for BASENAME in "${BASENAMES[@]}"; do
	mapfile -t CANDIDATES < <( for SNAPSHOT in "${SNAPSHOTS[@]}"; do echo $SNAPSHOT; done | grep "^${BASENAME}")
	PREV_AGE=0;
	KILLLIST=();
	for SNAPSHOT in "${CANDIDATES[@]}"; do
		SNAPDATE="${SNAPSHOT#${BASENAME}_}"
		SECONDS="$(date --utc -d "${SNAPDATE:0:4}-${SNAPDATE:4:2}-${SNAPDATE:6:2} ${SNAPDATE:9:2}:${SNAPDATE:11:2}:${SNAPDATE:13:2}" '+%s')"
		AGE=$(( NOW - SECONDS ))
		if (( 0 == PREV_AGE )); then
			PREV_AGE=$AGE
		elif (( MULTIPLIER * PREV_AGE < AGE )); then
			for (( I=0; I< ${#KILLLIST[@]}-1; I++ )); do
				echo "${VOLUME}/${KILLLIST[$I]}"
			done
			PREV_AGE=$AGE
			KILLLIST=("$SNAPSHOT")
		else
			KILLLIST=("${KILLLIST[@]}" "$SNAPSHOT")
		fi
	done
	for (( I=0; I< ${#KILLLIST[@]}-1; I++ )); do
		echo "${VOLUME}/${KILLLIST[$I]}"
	done
done
