# rsyncFacility - R package

This package offers convenience functions to copy and move
files and directories to and from a remote machine 
using `rsync`.

# Requirements
The package makes use of `rsync` available on Linux systems.
It has been tested with rsync version 3.1.2.
If the password is passed to the `initRsync` function 
as a character string or in a file, the command line
utility `sshpass` is needed in addition.

# Installation

If Git is present on the system, one way to install the package in a terminal window is:

```
git clone https://github.com/gschnabel/interactiveSSH.git
R CMD INSTALL rsyncFacility
```

# Basic usage

First, a connection object has to be instantiated via
```
library(rsyncFacility)
rsynCcon <- initRsync("user@host", "password", tempdir.loc="tempdir")
```
where `user@host` and `password` need to be replaced by the correct login credentials.
The object `rsyncCon` provides various functions, which can be shown by
typing `?initRsync` at the R prompt.


