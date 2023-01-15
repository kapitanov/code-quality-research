#!/bin/bash
set -Eeuo pipefail

ROOTDIR=$(dirname ${BASH_SOURCE[0]} | xargs dirname)
ROOTDIR=$(realpath $ROOTDIR)

function analyze_go() {
	URL="$1"

	DIR=$(git_fetch "$URL")
	echo "$URL" >>"$ROOTDIR/output/URLS"

	(cd $ROOTDIR/tools/scanner && go build -o $ROOTDIR/output/scanner > /dev/null)
	REPORT=$($ROOTDIR/output/scanner -i $DIR)
	echo "$REPORT" >>"$ROOTDIR/output/RAW"

	FILES=$(echo "$REPORT" | awk '{print $2}')
	TOTAL_LOC=$(echo "$REPORT" | awk '{print $3}')
	COMMENT_PART=$(echo "$REPORT" | awk '{print $5}')
	AVG_FILE_LOC=$(awk "BEGIN { print ($TOTAL_LOC/$FILES) }")
	AVG_FILE_LOC=$(awk -v scale=2 "BEGIN { printf \"%.*f\\n\", scale, $AVG_FILE_LOC }")

	URL=${URL%.git}
	echo "| [\`$(basename $DIR)\`]($URL) | \`$FILES\` | \`$TOTAL_LOC\` | \`$AVG_FILE_LOC\` | \`$COMMENT_PART%\` |" >>$ROOTDIR/output/table.md
}
