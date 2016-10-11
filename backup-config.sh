#!/bin/sh

# target ($2) must be a subvolume

sourceSubvol=$1
targetSubvol=$2
targetUUID=$(btrfs subvolume show $targetSubvol | grep "[^ ]UUID:" | awk '{print $2;}')
refDir="$sourceSubvol/.backuprefs/$targetUUID"
date=$(date +%F-%H-%M-%S)

backupIncremental() {
	sourceSubvol=$1
	targetSubvol=$2
	refDir=$3
	date=$4
	ref=$5

	echo "Using incremental method with $ref"
	btrfs subvolume snapshot -r $sourceSubvol "$refDir/$date"
	btrfs send -p $ref "$refDir/$date" | btrfs receive $targetSubvol
	btrfs subvolume delete "$ref"
	mv "$refDir/$date" "$ref"
}

backupSetup() {
	sourceSubvol=$1
	targetSubvol=$2
	refDir=$3
	date=$4
	ref=$5

	echo "Using setup method"
	mkdir -p $refDir
	btrfs subvolume snapshot -r $sourceSubvol "$refDir/$date"
	btrfs send "$refDir/$date" | btrfs receive $targetSubvol
	mv "$refDir/$date" "$ref"
}

echo "Backing up $sourceSubvol to $targetSubvol"

# check if a reference is existing
if [ -d "$refDir/ref" ]
then
	refUUID=$(btrfs subvolume show "$refDir/ref" | grep "[^ ]UUID:" | awk '{print $2;}')

	# check if any of the backup snapshots is related with the reference snapshot
	if [ "$(btrfs subvolume list -o -R $targetSubvol | grep $refUUID)" ]
	then
		backupIncremental $sourceSubvol $targetSubvol $refDir $date "$refDir/ref"
	else
		echo "Reference $refDir/ref is not related with existing backup snapshots at $targetDir"
		btrfs subvolume delete "$refDir/ref"
		backupSetup $sourceSubvol $targetSubvol $refDir $date "$refDir/ref"
	fi
else
	backupSetup $sourceSubvol $targetSubvol $refDir $date "$refDir/ref"
fi
