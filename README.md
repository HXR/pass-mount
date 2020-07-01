# pass-mount

A [pass](https://www.passwordstore.org/) extension for mounting encrypted
filesystems.

## Usage

```
Usage:

    pass mount pass-name
    pass mount target pass-name
        Mount encrypted filesystem using the configuration stored in pass-name.

    pass mount status pass-name
        Display status information about encrypted filesystem.

    pass mount init pass-name
        Initialize encrypted filesystem.

    pass umount pass-name
        Unmount encrypted filesystem

More information may be found in the pass-mount(1) man page.
```

## :rotating_light: WARNING :rotating_light:
Under "active" development  
Configuration format unstable and upgrade may require manual edits  
Cryfs is unstable - backup your data  
### 0.0.1 -> 0.1.0 Breaking changes
Cryfs based mountpoints now require `type: cryfs` in the [configuration](#example-config)

## NEWS
0.1.1
  Cryptsetup support
0.1.0
  Initial udisks support

## KNOWN BUGS/ISSUES
### Cryfs
- Some versions of cryfs block if /dev/random runs out of entropy
- [Cryfs is not a journaling filesystem](https://github.com/cryfs/cryfs/issues/209)

## TODO
- [ ] support additional encrypted filesystems
  - [ ] LUKS loopback
- [ ] Improve configuration system
  - [ ] Cryfs update check
  - [ ] Unmount idle time
  - [ ] Config validation
- [ ] support additional command line options
  - [ ] --version
  - [ ] `pass mount init --force pass-name` to overwrite config
- [ ] Implement unit tests
- [ ] CI

## Example Config
### Cryfs
Cryfs config -- multi-line entry in `pass`
```
encrypted-volume-password-here
type: cryfs
basedir: .cryfs/data
mountpoint: /home/username/data
```

### Udisks
`pass-mount` can handle encrypted LUKS volumes that have been created with `gnome-disks`.

The udisks config can be manually initialized via
`pass edit mount/mydisklabel`
The uuid can be determined by running
`findmnt --target /media/$USER/$DISK_LABEL --output SOURCE --noheadings`
while the encrypted volume has been manually mounted.

Udisks config -- multi-line entry in `pass`
```
encrypted-volume-password-here
type: udisks
uuid: 222254e3-c547-4b4e-823a-5181698e0a39
```

For operating systems such as Ubuntu where hot-plugging an encrypted volume will cause udisks to generate a password dialog, one of the following udev rules can be used to disable automatic mounting via udisks.
```
70-udisks-ignore-luks.rules
70-udisks-ignore-uuid.rules
```

### Cryptsetup
On systems without `udisks` installed `pass-mount` can mount encrypted LUKS volumes by calling `cryptsetup` via `sudo`.

A cryptsetup config can be manually initialized via
`pass edit mount/mydisklabel`
As an example, the uuid for /dev/sdb1 can be determined by running
`udevadm info /dev/sdb1 | grep ID_FS_UUID=`

cryptsetup config -- multi-line entry in `pass`
```
encrypted-volume-password-here
type: cryptsetup
uuid: 222254e3-c547-4b4e-823a-5181698e0a39
```

## Under development
Initial work for initialization of full-disk encryption in progrss
THIS WILL PROBABLY DESTROY YOUR SYSTEM
`pass mount init --type udisks -d /dev/sdb --label ORIGIN --dry-run disk/test`

## Installation

### From git

```
git clone https://github.com/humanxrobot/pass-mount
cd pass-mount
sudo make install
```

### Requirements
- cryfs
  https://github.com/cryfs/cryfs
- pass
  https://www.passwordstore.org/

## License
Based in part on [pass-otp](https://github.com/tadfisher/pass-otp/) by Tad Fisher

```
Copyright (C) 2018 HXR LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
```
