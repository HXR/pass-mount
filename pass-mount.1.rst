==========
pass-mount
==========
 
--------------------------------------------------------------
A Password Store extension for managing encrypted filesystems.
--------------------------------------------------------------
 
:Author: Lucid One <LucidOne@users.noreply.github.com>
:Date:   2018-03-06
:Copyright: GPLv3
:Version: 0.1.1
:Manual section: 1
:Manual group: Password Store Extension
 
SYNOPSIS
========

pass mount [`COMMAND`] [`OPTIONS`]... [`ARGS`]...

DESCRIPTION
===========

pass-mount extends the **pass**\ (1) utility with an interface to mount
encrypted filesystems. 

If no COMMAND is specified, COMMAND defaults to **target**.

COMMANDS
========

mount target `pass-name`
------------------------
Mount an encrypted filesystem from the password and configuration stored that 
is in `pass-name`. 

mount `pass-name`
-----------------
This is equivilent to the `target` command above.

mount status `pass-name`
------------------------
Display the status and configuration of an encrypted filesystem from the
configuration stored in `pass-name`.

mount init `pass-name`
----------------------
Initialize encrypted filesystem and store the configuration in `pass-name`.

umount `pass-name`
------------------
Unmount an encrypted filesystem.

OPTIONS
=======

help, -h, \--help
  Show usage message.

EXAMPLE CONFIG - CRYFS
======================
Configuration can be manually edited by using **pass edit** `pass-name`.
Relative directory paths in the config are automatically prepended with $HOME.
::

  my_password
  type: cryfs
  basedir: .cryfs/encrypted_dir
  mountpoint: /usr/local/data

EXAMPLE CONFIG - UDISKS
=======================
Configuration can be manually edited by using **pass edit** `pass-name`.
The uuid can be determined by running
**findmnt --target /media/$USER/$DISK_LABEL --output SOURCE --noheadings**
::

  my_password
  type: udisks
  uuid: 222254e3-c547-4b4e-823a-5181698e0a39

EXAMPLE CONFIG - CRYPTSETUP
===========================
Configuration can be manually edited by using **pass edit** `pass-name`.
The uuid for **/dev/sdb1** can be determined by running
**udevadm info /dev/sdb1 | grep ID_FS_UUID=**
::

  my_password
  type: cryptsetup
  uuid: 222254e3-c547-4b4e-823a-5181698e0a39

SEE ALSO
========
**pass**\ (1)
**cryfs**\ (1)

<https://github.com/humanxrobot/pass-mount>

COPYING
=======
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
