#!/bin/bash
set -e

ROOTDIR=$(dirname $0 | xargs dirname)

# DSL functions
SCRIPT='#!/bin/bash'
SCRIPT="$SCRIPT
set -e

source $ROOTDIR/scripts/git.sh
source $ROOTDIR/scripts/go.sh

[ -f $ROOTDIR/output/RAW ] && rm $ROOTDIR/output/RAW
[ -f $ROOTDIR/output/URLS ] && rm $ROOTDIR/output/URLS
mkdir -p $ROOTDIR/output

[ -f $ROOTDIR/output/table.md ] && rm -r $ROOTDIR/output/table.md
echo '| Project | Files | Total lines of code | Average LOC per file | Comments per code |' > $ROOTDIR/output/table.md
echo '|:---|---:|---:|---:|---:|' >> $ROOTDIR/output/table.md
"

# Load configuration using DSL functions and run the scripts
for file in $(find $ROOTDIR/sources.d/*); do
	printf "\e[1;33mLOAD\e[0m $file\n" >&2

	for URL in $(cat $file); do
		SCRIPT="$SCRIPT
analyze_go \"$URL\""
	done
done
SCRIPT="$SCRIPT

$ROOTDIR/scripts/report.sh
"

echo "$SCRIPT" >"$ROOTDIR/output/exec.sh"
chmod +x "$ROOTDIR/output/exec.sh"
"$ROOTDIR/output/exec.sh"
