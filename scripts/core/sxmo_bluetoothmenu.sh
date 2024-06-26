#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh

set -e

SIMPLE_MODE=yes

_prompt() {
	sxmo_dmenu.sh -i "$@"
}

_device_list() {
	bluetoothctl devices | \
		cut -d" " -f2 | \
		xargs -rn1 bluetoothctl info | \
		awk '
			function print_cached_device() {
				print icon linkedsep paired connected " " name " " mac
				name=icon=mac=""
			}
			{ $1=$1 }
			/^Device/ && name { print_cached_device() }
			/^Device/ { mac=$2; paired=""; connected=""; linkedsep="" }
			/Name:/ { $1="";$0=$0;$1=$1; name=$0 }
			/Paired: yes/ { paired="'$icon_lnk'"; linkedsep=" " }
			/Connected: yes/ { connected="'$icon_a2x'"; linkedsep=" " }
			/Icon: computer/ { icon="'$icon_com'" }
			/Icon: phone/ { icon="'$icon_phn'" }
			/Icon: modem/ { icon="'$icon_mod'" }
			/Appearance: 0x00c2/ { icon="'$icon_wat'" }
			/Icon: watch/ { icon="'$icon_wat'" }
			/Icon: network-wireless/ { icon="'$icon_wif'" }
			/Icon: audio-headset/ { icon="'$icon_hdp'" }
			/Icon: audio-headphones/ { icon="'$icon_spk'" }
			/Icon: camera-video/ { icon="'$icon_vid'" }
			/Icon: audio-card/ { icon="'$icon_mus'" }
			/Icon: input-gaming/ { icon="'$icon_gam'" }
			/Icon: input-keyboard/ { icon="'$icon_kbd'" }
			/Icon: input-tablet/ { icon="'$icon_drw'" }
			/Icon: input-mouse/ { icon="'$icon_mse'" }
			/Icon: printer/ { icon="'$icon_prn'" }
			/Icon: camera-photo/ { icon="'$icon_cam'" }
			END { print_cached_device() }
		'
}

_restart_bluetooth() {
	case "$SXMO_OS" in
		alpine|postmarketos)
			doas rc-service bluetooth restart
			;;
		arch|archarm|nixos)
			doas systemctl restart bluetooth
			;;
	esac
}

_full_reconnection() {
	sxmo_terminal.sh sh -c "
notify-send 'Make the device discoverable'

bluetoothctl remove '$1'
sxmo_jobs.sh start bluetooth_scan bluetoothctl --timeout 300 scan on

sleep 5

while : ; do
	timeout 7 bluetoothctl connect '$1'
	if bluetoothctl info '$1'  | grep -q 'Connected: yes'; then
		break
	fi
	sleep 1
done
"
	sxmo_jobs.sh stop bluetooth_scan
}

_notify_failure() {
	notify-send "Something failed"
}

_can_fail() {
	"$@" || _notify_failure
}

_show_toggle() {
	if [ "$1" = yes ]; then
		printf %s "$icon_ton"
	else
		printf %s "$icon_tof"
	fi
}

toggle_connection() {
	DEVICE="$1"
	MAC="$(printf "%s\n" "$DEVICE" | awk '{print $NF}')"

	if printf "%s\n" "$PICK" | grep -q "$icon_a2x"; then
		_can_fail timeout 7 sxmo_terminal.sh bluetoothctl disconnect "$MAC"
	else
		_can_fail timeout 7 sxmo_terminal.sh bluetoothctl connect "$MAC"
	fi
}

device_loop() {
	DEVICE="$1"
	MAC="$(printf "%s\n" "$DEVICE" | awk '{print $NF}')"
	INDEX=0
	while : ; do
		INFO="$(bluetoothctl info "$MAC")"
		PAIRED="$(printf "%s\n" "$INFO" | grep "Paired:" | awk '{print $NF}')"
		TRUSTED="$(printf "%s\n" "$INFO" | grep "Trusted:" | awk '{print $NF}')"
		BLOCKED="$(printf "%s\n" "$INFO" | grep "Blocked:" | awk '{print $NF}')"
		CONNECTED="$(printf "%s\n" "$INFO" | grep "Connected:" | awk '{print $NF}')"

		PICK="$(
			cat <<EOF |
$icon_ret Return
$icon_rld Refresh
Paired $(_show_toggle "$PAIRED")
Trusted $(_show_toggle "$TRUSTED")
Connected $(_show_toggle "$CONNECTED")
Blocked $(_show_toggle "$BLOCKED")
$icon_ror Clean re-connection
$icon_trh Remove
EOF
			_prompt -p "$DEVICE" -I "$INDEX"
		)"

		case "$PICK" in
			"$icon_ret Return")
				INDEX=0
				return
				;;
			"$icon_rld Refresh")
				INDEX=1
				continue
				;;
			"Paired $icon_tof")
				INDEX=2
				_can_fail timeout 7 sxmo_terminal.sh bluetoothctl "$MAC"
				;;
			"Trusted $icon_ton")
				INDEX=3
				_can_fail sxmo_terminal.sh bluetoothctl untrust "$MAC"
				;;
			"Trusted $icon_tof")
				INDEX=3
				_can_fail sxmo_terminal.sh bluetoothctl trust "$MAC"
				;;
			"Connected $icon_ton")
				INDEX=4
				_can_fail timeout 7 sxmo_terminal.sh bluetoothctl disconnect "$MAC"
				;;
			"Connected $icon_tof")
				INDEX=4
				_can_fail timeout 7 sxmo_terminal.sh bluetoothctl "$MAC"
				;;
			"Blocked $icon_ton")
				INDEX=5
				;;
			"Blocked $icon_tof")
				INDEX=5
				;;
			"$icon_ror Clean re-connection")
				_full_reconnection "$MAC"
				INDEX=6
				;;
			"$icon_trh Remove")
				INDEX=7
				(confirm_menu -p "Remove this device ?" \
					&& _can_fail sxmo_terminal.sh bluetoothctl remove "$MAC") \
					|| continue
				return
				;;
		esac
		sleep 0.5
	done
}

main_loop() {
	INDEX=0
	while : ; do
		INFO="$(bluetoothctl show)"
		DISCOVERING="$(printf "%s\n" "$INFO" | grep "Discovering:" | awk '{print $NF}')"
		PAIRABLE="$(printf "%s\n" "$INFO" | grep "Pairable:" | awk '{print $NF}')"

		DEVICES="$(_device_list)"

		PICK="$(
			cat <<EOF |
$icon_cls Close Menu
$icon_rld Refresh
$icon_pwr Restart daemon
Simple mode $(_show_toggle "$SIMPLE_MODE")
Pairable $(_show_toggle "$PAIRABLE")
Discovering $(_show_toggle "$DISCOVERING")
$DEVICES
EOF
			_prompt -p "$icon_bth Bluetooth" -I "$INDEX"
		)"

		case "$PICK" in
			"$icon_cls Close Menu")
				INDEX=0
				exit
				;;
			"$icon_rld Refresh")
				INDEX=1
				continue
				;;
			"$icon_pwr Restart daemon")
				INDEX=2
				confirm_menu -p "Restart the daemon ?" && _restart_bluetooth
				;;
			"Simple mode $icon_ton")
				SIMPLE_MODE=no
				INDEX=3
				;;
			"Simple mode $icon_tof")
				SIMPLE_MODE=yes
				INDEX=3
				;;
			"Pairable $icon_ton")
				bluetoothctl pairable off
				INDEX=4
				;;
			"Pairable $icon_tof")
				bluetoothctl pairable on
				INDEX=4
				;;
			"Discovering $icon_ton")
				INDEX=5
				sxmo_jobs.sh stop bluetooth_scan
				sleep 0.5
				;;
			"Discovering $icon_tof")
				sxmo_jobs.sh start bluetooth_scan bluetoothctl --timeout 60 scan on > /dev/null
				notify-send "Scanning for 60 seconds"
				INDEX=5
				sleep 0.5
				;;
			*)
				INDEX=0

				if [ "$SIMPLE_MODE" = no ]; then
					device_loop "$PICK"
				else
					toggle_connection "$PICK"
				fi
				;;
		esac
	done
}

main_loop
