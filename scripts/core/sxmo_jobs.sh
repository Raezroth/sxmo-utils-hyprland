#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

ROOT="$XDG_RUNTIME_DIR/sxmo_jobs"
mkdir -p "$ROOT"

exec 3<> "$XDG_RUNTIME_DIR/sxmo.jobs.lock"
flock -x 3

list() {
	find "$ROOT" -mindepth 1 -exec 'basename' '{}' ';'
}

stop() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-f)
				force=1
				shift
				;;
			*)
				id="$1"
				shift
				break
				;;
		esac
	done

	case "$id" in
		all)
			list | while read -r sub_id; do
				stop "$sub_id"
			done
			;;
		*)
			if [ -f "$ROOT/$id" ]; then
				sxmo_debug "stop $id"
				xargs kill ${force:+-9} < "$ROOT"/"$id" 2> /dev/null
				rm "$ROOT"/"$id"
			fi
			;;
	esac
}

signal() {
	id="$1"
	shift

	if [ -f "$ROOT/$id" ]; then
		sxmo_debug "signal $id $*"
		xargs kill "$@" < "$ROOT"/"$id" 2> /dev/null
	fi
}

start() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			--no-restart)
				no_restart=1
				shift
				;;
			*)
				id="$1"
				shift
				break
				;;
		esac
	done

	if [ -f "$ROOT/$id" ]; then
		if [ -n "$no_restart" ]; then
			sxmo_debug "$id already running"
			exit 1
		else
			stop "$id"
		fi
	fi

	sxmo_debug "start $id"
	(
		# We need a subshell so we can close the lock fd, without
		# releasing the lock
		exec 3<&-
		"$@" &
		printf "%s\n" "$!" > "$ROOT"/"$id"
	)
}

running() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-q)
				quiet=1
				shift
				;;
			*)
				id="$1"
				shift
				;;
		esac
	done

	log() {
		if [ -z "$quiet" ]; then
			# shellcheck disable=SC2059
			printf "$@"
		fi
	}

	if [ -f "$ROOT/$id" ]; then
		pid="$(cat "$ROOT/$id")"
		if [ -d "/proc/$pid" ]; then
			log "%s is still running\n" "$id"
		else
			log "%s is not running anymore\n" "$id"
			exit 2
		fi
	else
		log "%s is not running\n" "$id"
		exit 1
	fi
}

"$@"
