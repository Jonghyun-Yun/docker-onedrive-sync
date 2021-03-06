#!/usr/bin/with-contenv sh

# check a refresh token exists
if [ -f /odrive/.config/refresh_token ]; then
  echo "Found onedrive refresh token..."
else
  echo
  echo "-------------------------------------"
  echo "ONEDRIVE LOGIN REQUIRED"
  echo "-------------------------------------"
  echo "To use this container you must authorize the OneDrive Client."

  if [ -t 0 ] ; then
    echo "-------------------------------------"
    echo
  else
    echo
    echo "Please re-start start the container in interactive mode using the -it flag:"
    echo
    echo "Once authorized you can re-create container with interactive mode disabled."
    echo "-------------------------------------"
    echo
    exit 1
  fi

fi

# This script is a fork of https://github.com/excelsiord/docker-dropbox

# Set UID/GID if not provided with enviromental variable(s).
if [ -z "$PUID" ]; then
	PUID=$(cat /etc/passwd | grep onedrive | cut -d: -f3)
	echo "PUID variable not specified, defaulting to onedrive user id ($PUID)"
fi

if [ -z "$PGID" ]; then
	PGID=$(cat /etc/group | grep onedrive | cut -d: -f3)
	echo "PGID variable not specified, defaulting to onedrive user group id ($PGID)"
fi

# Look for existing group, if not found create dropbox with specified GID.
FIND_GROUP=$(grep ":$PGID:" /etc/group)

if [ -z "$FIND_GROUP" ]; then
	usermod -g users onedrive
	groupdel onedrive
	groupadd -g $PGID onedrive
fi

# Set dropbox account's UID.
usermod -u $PUID -g $PGID --non-unique onedrive > /dev/null 2>&1

# Change ownership to dropbox account on all working folders.
chown -R $PUID:$PGID /odrive
chown -R $PUID:$PGID /root

# Change permissions on Dropbox folder
chmod 755 /odrive/OneDrive

# turn on or off verbose logging
if [ "$DEBUG" = "1" ]; then
  VERBOSE=true
else
  VERBOSE=false
fi

echo "Starting onedrive client..."

# s6-setuidgid abc onedrive --monitor --confdir=/config --syncdir=/documents --verbose=${VERBOSE}

s6-setuidgid onedrive /usr/local/bin/onedrive --monitor --syncdir=/odrive/OneDrive --confdir=/odrive/.config

