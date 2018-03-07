# pass-mount

A [pass](https://www.passwordstore.org/) extension for mounting encrypted
filesystems.

/WARNING/: Under active development
/WARNING/: Configuration format unstable and upgrade may require manual edit
/WARNING/: Cryfs is unstable - backup your data

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

## NEWS
0.0.1
  Initial release! :cool:

## KNOWN BUGS
- Some versions of cryfs block if /dev/random runs out of entropy
- Cryfs is not a journaling filesystem (#209)[https://github.com/cryfs/cryfs/issues/209]

## TODO
- [ ] support additional encrypted filesystems
  - [ ] LUKS loopback
  - [ ] Mouting LUKS filesystems by UUID
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
```
encrypted-volume-password-here
basedir: .cryfs/data
mountpoint: /home/username/data
```

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
Based in part on (pass-otp)[https://github.com/tadfisher/pass-otp/] by Tad Fisher

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
