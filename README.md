# rsyncFacility - R package

This package offers convenience functions to copy and move
files and directories to and from a remote machine 
using `rsync`.

## Requirements
The package makes use of `rsync` available on Linux systems.
It has been tested with rsync version 3.1.2.
If the password is passed to the `initRsync` function 
as a character string or in a file, the command line
utility `sshpass` is needed in addition.

## Installation

If Git is present on the system, one way to install the package in a terminal window is:

```
git clone https://github.com/gschnabel/interactiveSSH.git
R CMD INSTALL rsyncFacility
```

## Basic usage

First, a connection object has to be instantiated via
```
library(rsyncFacility)
rsynCcon <- initRsync("user@host", "password", tempdir.loc="tempdir")
```
where `user@host` and `password` need to be replaced by the correct login credentials.
The object `rsyncCon` provides various functions, which can be shown by
typing `?initRsync` at the R prompt.

As an example, a file `srcfile` can be duplicated on the remote machine as file 'destfile`
using the command
```
rsyncCon$upSyncFile('srcfile', 'destfile')
```
Similarly, a directory can be copied to the remote machine by
```
rsyncCon$upSyncDir('srcdir/', 'destdir')
```
A trailing slash in source path indicates that the contents of `srcdir` should be copied
into `destdir`.
Without the trailing slash, the directory `srcdir` itself is copied into `destdir` on the
remote machine.

