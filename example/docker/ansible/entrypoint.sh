#!/bin/sh

# do not detach (-D), log to stderr (-e), passthrough other arguments
#exec /usr/sbin/sshd -D -e "$@"

# start jupyter.
exec jupyter lab --ip=0.0.0.0 --allow-root --no-browser --notebook-dir=/home
