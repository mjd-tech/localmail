#!/bin/bash

# exit immediately if a command fails
set -e

# When container starts, this script runs, its arguments are whatever is in
# the CMD entry in the Dockerfile, in this case "postfix -v start-fg"
# This can be overridden. Usually with "docker run -it imagename bash"

# If default is overridden, execute the override command, which exits this script. 
[[ "$1" != "postfix" ]] && exec "$@"

# No override, do a normal startup.
echo "Starting mail server:"
echo "HOSTNAME=${MY_HOSTNAME}"; echo

# read template, substitute variable, write to config file 
envsubst '\$MY_HOSTNAME' < main.cf.template > /etc/postfix/main.cf
 
# Set password for localmail user
echo "localmail:$MY_PASSWORD" | chpasswd || true
    
# postfix needs fresh copies of files in its chroot jail
cp /etc/{hosts,localtime,nsswitch.conf,resolv.conf,services} /var/spool/postfix/etc/

# run dovecot imap server  
dovecot

# run the command given in the Dockerfile.
exec "$@"

