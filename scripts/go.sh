#!/bin/bash

ROOTDIR=$(dirname ${BASH_SOURCE[0]} | xargs dirname)

function go() {
	URL="$1"

	DIR=$(git_fetch "$URL")
	echo "$URL" >>"$ROOTDIR/output/raw/URLS"

	REPORT=$(gocloc --not-match-d=vendor --match='.*\.go' --output-type=sloccount $DIR | grep -E 'Go.+')

	FILES=$(echo "$REPORT" | awk '{print $2}')
	COMMENTS_LOC=$(echo "$REPORT" | awk '{print $4}')
	TOTAL_LOC=$(echo "$REPORT" | awk '{print $5}')
	AVG_LOC=$(awk "BEGIN { print ($TOTAL_LOC/$FILES) }")
	COMMENT_PART=$(awk "BEGIN { print (100.0 * $COMMENTS_LOC/$TOTAL_LOC) }")

	echo "$FILES" >>"$ROOTDIR/output/raw/FILES"
	echo "$TOTAL_LOC" >>"$ROOTDIR/output/raw/TOTAL_LOC"
	echo "$COMMENT_PART" >>"$ROOTDIR/output/raw/COMMENT_PART"

	COMMENT_PART=$(awk -v scale=2 "BEGIN { printf \"%.*f\\n\", scale, $COMMENT_PART }")
	URL=${URL%.git}
	echo "| [\`$(basename $DIR)\`]($URL) | $FILES | $TOTAL_LOC | $COMMENT_PART% |" >>$ROOTDIR/output/table.md
}
