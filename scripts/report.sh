#!/bin/bash
set -e

ROOTDIR=$(dirname $0 | xargs dirname)

function round() {
	VALUE="$1"
	SCALE="$2"
	[ -z "$VALUE" ] && read -r VALUE
	[ -z "$SCALE" ] && SCALE=2

	RESULT=$(awk "BEGIN { printf \"%02.*f\\n\", $SCALE, $VALUE }")
	echo "$RESULT"
}

function min_value() {
	FILE="$1"

	VALUE=

	for line in $(cat "$FILE"); do
		if [ -z "$VALUE" ]; then
			VALUE="$line"
		else
			if [ "$(echo "$line < $VALUE" | bc)" -eq 1 ]; then
				VALUE="$line"
			fi
		fi
	done

	echo "$VALUE"
}

function max_value() {
	FILE="$1"

	VALUE=

	for line in $(cat "$FILE"); do
		if [ -z "$VALUE" ]; then
			VALUE="$line"
		else
			if [ "$(echo "$line > $VALUE" | bc)" -eq 1 ]; then
				VALUE="$line"
			fi
		fi
	done

	echo "$VALUE"
}

function average() {
	FILE="$1"
	COUNT=0
	SUM=0

	for line in $(cat "$FILE"); do
		SUM=$(echo "$SUM + $line" | bc)
		COUNT=$(echo "$COUNT + 1" | bc)
	done

	VALUE=$(echo "$SUM / $COUNT" | bc)
	echo "$VALUE"
}

function sum() {
	FILE="$1"
	SUM=0

	for line in $(cat "$FILE"); do
		SUM=$(echo "$SUM + $line" | bc)
	done

	echo "$SUM"
}

function percentile() {
	FILE="$1"
	PERCENTILE="$2"
	AWK_SCRIPT="{ all[NR] = \$0 } END { print all[int(NR*0.$PERCENTILE - 0.5)] }"
	RESULT=$(sort "$FILE" -n | awk "$AWK_SCRIPT")
	RESULT=$(awk -v scale=2 "BEGIN { printf \"%.*f\\n\", scale, $RESULT }")
	echo "$RESULT"
}

function print_report() {
	echo "# Report"
	echo ""
	echo "## How many comments per file?"
	echo ""
	echo "| Parameter | Value    |"
	echo "|:----------|---------:|"
	echo "| Min       | \`$(min_value "$ROOTDIR/output/raw/COMMENT_PART"  | round)%\` |"
	echo "| Max       | \`$(max_value "$ROOTDIR/output/raw/COMMENT_PART"  | round)%\` |"
	echo "| Average   | \`$(average "$ROOTDIR/output/raw/COMMENT_PART"  | round)%\` |"
	echo "| P99:      | \`$(percentile "$ROOTDIR/output/raw/COMMENT_PART" 99 | round)%\` |"
	echo "| P95:      | \`$(percentile "$ROOTDIR/output/raw/COMMENT_PART" 95 | round)%\` |"
	echo "| P90:      | \`$(percentile "$ROOTDIR/output/raw/COMMENT_PART" 90 | round)%\` |"
	echo "| P75:      | \`$(percentile "$ROOTDIR/output/raw/COMMENT_PART" 75 | round)%\` |"
	echo "| P50:      | \`$(percentile "$ROOTDIR/output/raw/COMMENT_PART" 50 | round)%\` |"
	echo ""
	echo "$(sum "$ROOTDIR/output/raw/FILES") files were analyzed."
	echo "$(sum "$ROOTDIR/output/raw/TOTAL_LOC") lines of code were scanned."
	echo ""
	echo "## Sources"
	echo ""
	for URL in $(cat "$ROOTDIR/output/raw/URLS"); do
		echo "- [${URL#https://}]($URL)"
	done
	echo ""
}

print_report >"$ROOTDIR/output/report.md"
printf "\e[1;33mREPORT\e[0m $ROOTDIR/output/report.md\n" >&2
printf "\n\n%s\n" "$(cat $ROOTDIR/output/report.md)" >&2
