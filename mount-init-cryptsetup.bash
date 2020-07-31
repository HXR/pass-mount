#!/usr/bin/env bash
# pass mount-init - Password Store Extension (https://www.passwordstore.org/)
# Copyright (C) 2020 T5CC
# based in part on pass-otp by Tad Fisher
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
set -o pipefail

CRYPTSETUP=$(which cryptsetup)
CRYPTSETUP_PASS_LENGTH=25
CRYPTSETUP_ARGS="--type luks2 --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 8192 --use-random"

cmd_mount_cryptsetup_init() {
	local pass
	local passfile="$PREFIX/$path.gpg"
	check_sneaky_paths "$path"

	if [[ ! $mount_dev ]]; then
		cmd_mount_cryptsetup_get_dev
	fi
	[[ -b $mount_dev ]] || die "Error: Block device $mount_dev not found"

	mapfile sudo_cmd <<-_EOF
		parted --script $mount_dev print || true
		read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
		echo "Processing..."
		parted --script --align optimal $mount_dev mklabel gpt
		parted --script --align optimal $mount_dev mkpart primary 0% 100%
		partprobe $mount_dev
	_EOF

	if [[ $mount_dev =~ [[:digit:]]$ ]]; then
		mount_part="${mount_dev}p1"
	else
		mount_part="${mount_dev}1"
	fi

	format_cmd="$CRYPTSETUP $CRYPTSETUP_ARGS luksFormat ${mount_part}"
	uuid_cmd="$CRYPTSETUP luksUUID ${mount_part}"

	[[ ! -f "$PREFIX/$path.gpg" ]] || die "Error: $path already exists"
	if [[ $dry_run -ne 0 ]]; then
		echo "pass generate $path $CRYPTSETUP_PASS_LENGTH >& /dev/null"
		echo "sudo -- bash -c \"set -eo pipefail; \\"
		echo " ${sudo_cmd[@]}\""
		echo "[[ -b $mount_part ]] || die \"Error: Partition $mount_part not found\""
		echo "sudo -- bash -c \"$format_cmd\""
		echo "CRYPTSETUP_UUID=\$(sudo -- bash -c \"$uuid_cmd\")"
		echo "sudo -- bash -c \"$CRYPTSETUP open --type=luks ${mount_part} luks-\$CRYPTSETUP_UUID\""
		echo "sudo -- bash -c \"mkfs.ext4${mount_label:+ -L $mount_label} /dev/mapper/luks-\$CRYPTSETUP_UUID\""
		echo "sudo -- bash -c \"$CRYPTSETUP close luks-\$CRYPTSETUP_UUID\""
		echo "# run 'pass edit $path' and append"
		echo "type: $mount_type"
		echo "uuid: \$CRYPTSETUP_UUID"
		exit
	else
		pass generate $path $CRYPTSETUP_PASS_LENGTH >& /dev/null || exit $?
		pass="$($GPG -d "${GPG_OPTS[@]}" "$passfile" | head -n 1)" || exit $?
		sudo -- bash -c "set -eo pipefail; ${sudo_cmd[*]}"
		[[ -b $mount_part ]] || die "Error: Partition $mount_part not found"
		printf '%s' $pass | sudo -- bash -c "$format_cmd"
		CRYPTSETUP_UUID=$(sudo -- bash -c "$uuid_cmd")
		echo CRYPTSETUP_UUID=$CRYPTSETUP_UUID
		printf '%s' $pass | sudo -- bash -c "$CRYPTSETUP open --type=luks ${mount_part} luks-$CRYPTSETUP_UUID"
		sudo -- bash -c "mkfs.ext4${mount_label:+ -L $mount_label} /dev/mapper/luks-$CRYPTSETUP_UUID"
		sleep 5 && sync
		sudo -- bash -c "$CRYPTSETUP close luks-$CRYPTSETUP_UUID"
		printf '%s\ntype: %s\nuuid: %s\n' $pass $mount_type $CRYPTSETUP_UUID | pass insert --multiline --force $path
	fi

}

cmd_mount_cryptsetup_get_dev() {
	[[ "$(uname -s)" = "Linux" ]] || die "Error: Unknown Kernel"
	[[ -d /sys/block ]] || die "Error: Unable to locate block devices in sysfs"

	BOOT_PART=$(findmnt --noheadings --target /boot --output SOURCE)
	[[ -b "$BOOT_PART" ]] && BOOT_DEV="$(lsblk --noheadings --output PKNAME ${BOOT_PART})"

	echo "Device        Type    Info"
	for device in /sys/block/* ; do
		device=$(basename "$device")
		[[ "$device" != dm-* ]] || continue
		[[ "$device" != loop* ]] || continue
		[[ "$device" != md* ]] || continue
		[[ "$device" != ${BOOT_DEV:-sda} ]] || continue
		read device_vendor < "/sys/block/$device/device/vendor"
		read device_model < "/sys/block/$device/device/model"
		device_bus=$(udevadm info "/dev/$device" | grep ID_BUS | cut -d= -f2)
		printf '%-14s%-8s%s\n' \
			"/dev/$device" "${device_bus:-unknown}" "$device_vendor $device_model"
	done

	echo
	while [[ ! $mount_dev || ! -b $mount_dev ]]; do
		if [ $mount_dev ]; then
			echo Block device $mount_dev not found
		fi
		read -r -p "Device: " -e mount_dev
		if [ ! $mount_dev ]; then
			exit 1
		fi
	done
}
