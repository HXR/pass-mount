#!/usr/bin/env bash
# pass umount - Password Store Extension (https://www.passwordstore.org/)
# Copyright (C) 2018 HXR LLC
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

FUSERMOUNT=$(which fusermount)

umount_config() {
  local contents
  local path="$1"
  local passfile="$PREFIX/$path.gpg"
  check_sneaky_paths "$path"
  [[ ! -f $passfile ]] && die "Passfile not found"

  contents=$($GPG -d "${GPG_OPTS[@]}" "$passfile")
  while read -r -a line; do
    if [[ "$line" == type: ]]; then
      mount_type="${line[1]}"
    fi
    if [[ "$line" == uuid: ]]; then
      mount_uuid="${line[1]}"
    fi
    if [[ "$line" == mountpoint: ]]; then
      mount_mountpoint="${line[1]}"
      if [[ ! "$mount_mountpoint" =~ ^/ ]]; then
        mount_mountpoint="$HOME/$mount_mountpoint"
      fi
    fi 
  done <<< "$contents"
}

cmd_umount_usage() {
  cat <<-_EOF
Usage:

    $PROGRAM umount pass-name
        Unmount encrypted filesystem

More information may be found in the pass-mount(1) man page.
_EOF
  exit 0
}

cmd_umount_target() {
  umount_config "$1"
  local path="$1"
  case "$mount_type" in
    cryfs)          shift; cmd_umount_cryfs_target ;;
    udisks)         shift; cmd_umount_udisks_target ;;
    cryptsetup)     shift; cmd_umount_cryptsetup_target ;;
    *)              die "Error: Invalid config 'type: $mount_type'" ;;
  esac
}

cmd_umount_cryfs_target() {
  mountpoint "$mount_mountpoint" > /dev/null || die "mountpoint:$mount_mountpoint already unmounted"
  $FUSERMOUNT -u "$mount_mountpoint"
}

cmd_umount_udisks_target() {
  [[ -e "/dev/mapper/luks-$mount_uuid" ]] || die "mountpoint:$path already unmounted"
  udisksctl unmount --block-device /dev/mapper/luks-$mount_uuid
  udisksctl lock --block-device /dev/disk/by-uuid/$mount_uuid
}

cmd_umount_cryptsetup_target() {
  mapfile sudo_cmd <<_EOF
export mount_label=\$(e2label /dev/mapper/luks-$mount_uuid || echo "unknown")
umount /media/crypt/\$mount_label
cryptsetup close luks-$mount_uuid
rmdir /media/crypt/\$mount_label
_EOF

  [[ -e "/dev/mapper/luks-$mount_uuid" ]] || die "$path [$mount_uuid] is not mounted"
  sudo -- bash -c "${sudo_cmd[*]}"
}

case "$1" in
  help|--help|-h) shift; cmd_umount_usage "$@" ;;
  init)           shift; cmd_umount_usage "$@" ;;
  status)         shift; cmd_umount_usage "$@" ;;
  target)         shift; cmd_umount_target "$@" ;;
  *)                     cmd_umount_target "$@" ;;
esac
exit 0
