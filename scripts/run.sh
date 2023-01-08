#!/bin/bash
set -e

ROOTDIR=$(dirname $0 | xargs dirname)

# DSL functions
SCRIPT='#!/bin/bash'
SCRIPT="$SCRIPT
set -e

source $ROOTDIR/scripts/git.sh
source $ROOTDIR/scripts/go.sh

[ -d $ROOTDIR/output/raw ] && rm -r $ROOTDIR/output/raw
mkdir $ROOTDIR/output/raw

[ -f $ROOTDIR/output/table.md ] && rm -r $ROOTDIR/output/table.md
echo '| Project | Files | Total lines of code | Comments per code |' > $ROOTDIR/output/table.md
echo '|---|---|---|---|' >> $ROOTDIR/output/table.md
"

function GO() {
	URL="$1"
	# name
	SCRIPT="$SCRIPT
go \"$URL\""
}

# Load configuration using DSL functions and run the scripts
for file in $(find $ROOTDIR/sources.d/*); do
	printf "\e[1;33mLOAD\e[0m $file\n" >&2
	chmod +x $file
	source $file
done
SCRIPT="$SCRIPT

$ROOTDIR/scripts/report.sh
"

echo "$SCRIPT" >"$ROOTDIR/output/exec.sh"
chmod +x "$ROOTDIR/output/exec.sh"
"$ROOTDIR/output/exec.sh"
