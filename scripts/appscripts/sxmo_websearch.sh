#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors
# title="$icon_glb Web Search"
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

SEARCHQUERY="$(echo "Close Menu" | sxmo_dmenu.sh -p "Search:")" || exit 0

case "$SEARCHQUERY" in
	"Close Menu") exit 0 ;;
	*) $BROWSER "https://duckduckgo.com/?q=${SEARCHQUERY}" ;;
esac
