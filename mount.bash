#!/usr/bin/env bash
# pass mount - Password Store Extension (https://www.passwordstore.org/)
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

CRYFS=$(which cryfs)

MOUNT_OPTS=(
  --unmount-idle 10
)

mount_export_env() {
  export CRYFS_FRONTEND=noninteractive
  export CRYFS_NO_UPDATE_CHECK=true
}

mount_config() {
  local contents
  local path="$1"
  local passfile="$PREFIX/$path.gpg"
  check_sneaky_paths "$path"
  [[ ! -f $passfile ]] && die "Passfile not found"

  contents=$($GPG -d "${GPG_OPTS[@]}" "$passfile")
  mount_password=${contents%%$'\n'*}
  while read -r -a line; do
    if [[ "$line" == basedir: ]]; then 
      mount_basedir="${line[1]}"
      if [[ ! "$mount_basedir" =~ ^/ ]]; then
        mount_basedir="$HOME/$mount_basedir"
      fi
    fi 
    if [[ "$line" == mountpoint: ]]; then 
      mount_mountpoint="${line[1]}"
      if [[ ! "$mount_mountpoint" =~ ^/ ]]; then
        mount_mountpoint="$HOME/$mount_mountpoint"
      fi
    fi 
  done <<< "$contents"
}

cmd_mount_usage() {
  cat <<-_EOF
Usage:

    $PROGRAM mount pass-name
    $PROGRAM mount target pass-name
        Mount encrypted filesystem using the configuration stored in pass-name.

    $PROGRAM mount status pass-name
        Display status information about encrypted filesystem.

    $PROGRAM mount init pass-name
        Initialize encrypted filesystem.

More information may be found in the pass-mount(1) man page.
_EOF
  exit 0
}

cmd_mount_init() {
  local path="$1"

  if [[ -t 0 ]]; then
    read -e -r -p "Enter the directory for storing encrypted data for $path: " mount_basedir || exit 1
  else
    read -r mount_basedir
  fi
  if [[ $mount_basedir =~ ^~/ ]]; then
    mount_basedir=${mount_basedir#"~/"}
  elif [[ $mount_basedir =~ $'~' ]]; then
    die "basedir:$mount_basedir invalid path - Can not init other users storage"
  fi

  if [[ -t 0 ]]; then
    read -e -r -p "Enter the directory for mounting unencrypted data for $path: " mount_mountpoint || exit 1
  else
    read -r mount_mountpoint
  fi
  if [[ $mount_mountpoint =~ ^~/ ]]; then
    mount_mountpoint=${mount_mountpoint#"~/"}
  elif [[ $mount_mountpoint =~ $'~' ]]; then
    die "mountpoint:$mount_mountpoint invalid path - Can not init other users storage"
  fi

  if [[ -t 0 ]]; then
    read -r -p "Enter encryption password: " -s mount_password || exit 1
    echo
    read -r -p "Retype encryption password: " -s mount_password_again || exit 1
    echo
    [[ "$mount_password" == "$mount_password_again" ]] || die "Error: the entered passwords do not match."
  else
      read -r mount_password
  fi

  local contents
  contents="$mount_password
basedir: $mount_basedir
mountpoint: $mount_mountpoint"

  local passfile="$PREFIX/$path.gpg"
  [[ -e $passfile ]] && die "An entry already exists for $path."

  check_sneaky_paths "$path"
  set_git "$passfile"

  mkdir -p -v "$PREFIX/$(dirname "$path")"
  set_gpg_recipients "$(dirname "$path")"

  $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile" "${GPG_OPTS[@]}" <<<"$contents" || die "Mount configuration encryption aborted."

  git_add_file "$passfile" "Add mount information for $path to store."

  if [[ ! "$mount_basedir" =~ ^/ ]]; then
    mount_basedir="$HOME/$mount_basedir"
  fi
  if [[ ! -d "$mount_basedir" ]]; then
    mkdir -p "$mount_basedir" > /dev/null
  else
    die "basedir:$mount_basedir already exists"
  fi

  if [[ ! "$mount_mountpoint" =~ ^/ ]]; then
    mount_mountpoint="$HOME/$mount_mountpoint"
  fi
  if [[ ! -d "$mount_mountpoint" ]]; then
    mkdir -p "$mount_mountpoint" > /dev/null
  else
    die "mountpoint:$mount_mountpoint already exists"
  fi

  mount_export_env
  $CRYFS "${MOUNT_OPTS[@]}" "$mount_basedir" "$mount_mountpoint" >/dev/null <<<"$mount_password"
}

cmd_mount_target() {
  mount_config "$1"
  local path="$1"
  [[ ! -d "$mount_basedir" ]] && die "basedir:$mount_basedir not found - Run '$PROGRAM $COMMAND init $path' to initialize"
  [[ ! -f "$mount_basedir/cryfs.config" ]] && die "config:$mount_basedir/cryfs.config not found - Run '$PROGRAM $COMMAND init $path' to initialize"
  [[ ! -d $mount_mountpoint ]] && die "mountpoint:$mount_mountpoint not found - Run '$PROGRAM $COMMAND init $path' to initialize"
  mountpoint "$mount_mountpoint" > /dev/null && die "mountpoint:$mount_mountpoint already mounted"
  [[ "$( find "$mount_mountpoint" -mindepth 1 -maxdepth 1 | wc -l )" -ne 0 ]] && die "mountpoint:$mount_mountpoint not empty - Check target mountpoint"

  mount_export_env
  $CRYFS "${MOUNT_OPTS[@]}" "$mount_basedir" "$mount_mountpoint" >/dev/null <<<"$mount_password"
}

cmd_mount_status() {
  mount_config "$1"
  if [[ -d "$mount_basedir" ]] && [[ -f "$mount_basedir/cryfs.config" ]]; then
    echo "basedir: $mount_basedir initialized"
  else
    echo "basedir: $mount_basedir is not initialized - Run '$PROGRAM $COMMAND init $path' to initialize"
  fi

  if [[ $(eval mountpoint "$mount_mountpoint") =~ is\ a\ mountpoint$ ]]; then
    echo "mountpoint: $mount_mountpoint is mounted"
  elif [[ -d $mount_mountpoint ]]; then
    echo "mountpoint: $mount_mountpoint is unmounted"
  else
    echo "mountpoint: $mount_mountpoint is not initialized - Run '$PROGRAM $COMMAND init $path' to initialize"
  fi
}

case "$1" in
  help|--help|-h) shift; cmd_mount_usage "$@" ;;
  init)           shift; cmd_mount_init "$@" ;;
  status)         shift; cmd_mount_status "$@" ;;
  target)         shift; cmd_mount_target "$@" ;;
  *)                     cmd_mount_target "$@" ;;
esac
exit 0
