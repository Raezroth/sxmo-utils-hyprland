#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

envvars() {
	export SXMO_WM=hyprland
	export MOZ_ENABLE_WAYLAND=1
	export SDL_VIDEODRIVER=wayland
	export XDG_CURRENT_DESKTOP=Hyprland
	# shellcheck disable=SC2086
	command -v $SXMO_TERMINAL "" >/dev/null || export SXMO_TERMINAL="kitty"
	command -v "$KEYBOARD" >/dev/null || export KEYBOARD=wvkbd-mobintl
	[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
}

defaults() {
	[ -e "$HOME"/.Xresources ] && xrdb -merge "$HOME"/.Xresources
}

with_dbus() {
	echo "$DBUS_SESSION_BUS_ADDRESS" > "$XDG_RUNTIME_DIR"/dbus.bus
	exec Hyprland
}

cleanup() {
	sxmo_jobs.sh stop all
	pkill bemenu
	pkill wvkbd
	pkill superd
}

# shellcheck source=scripts/core/sxmo_init.sh
. sxmo_init.sh
