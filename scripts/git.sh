#!/bin/bash
set -e

ROOTDIR=$(dirname ${BASH_SOURCE[0]} | xargs dirname)

function git_fetch() {
	URL="$1"

	LOCALDIR=$(_git_get_local_dir "$URL")

	if [ ! -d "$LOCALDIR/.git" ]; then
		_git_clone "$URL" "$LOCALDIR"
	else
		_git_pull "$LOCALDIR"
	fi

	echo "$LOCALDIR"
}

function _git_get_local_dir() {
	URL="$1"

	URL=${URL#https://}
	URL=${URL#http://}
	URL=${URL%.git}

	echo "$ROOTDIR/data/$URL"
}

function _git_clone() {
	URL="$1"
	LOCALDIR="$2"

	printf "\e[1;33mCLONE\e[0m $URL\n" >&2
	git clone "$URL" "$LOCALDIR" >&2
}

function _git_pull() {
	if [ -n $NO_PULL ]; then
	printf "\e[1;33mUPTODATE\e[0m $URL\n" >&2
		return
	fi

	LOCALDIR="$1"

	printf "\e[1;33mPULL\e[0m $URL\n" >&2
	(cd "$LOCALDIR" && git pull) >&2
}
