#!/bin/sh

# Simple script to automatically update all opkg packages on router

# Author: NoNameForMee (github), 2020
# License: GNU GENERAL PUBLIC LICENSE, GPL-3.0-or-later
# Full text available at https://www.gnu.org/licenses/gpl-3.0.html

# Check if we are using plain text http:// instead of encrypted and 
# verified https:// for the connection to the repos.
# If plain text http is used then we have likely just flashed a new
# firmware verison, try to change to https://.
if grep -q "http:" /etc/opkg/distfeeds.conf;
then
  echo "Repos was plain text http:// which is not optimal..."
  # Add required packages to avoid errors such as:
  # "wget: SSL support not available, please install one of the 
  #  libustream-.*[ssl|tls] packages as well as the ca-bundle and
  #  ca-certificates packages."
  echo "Installing required packages for https://..."
  opkg install ca-certificates libustream-openssl20150806
  # Now change from plain text http to https for repos
  sed -i 's/http:/https:/' /etc/opkg/distfeeds.conf
fi

# Update the list of packages from repo
opkg update
# Check which packages (if any) is upgradable
TO_BE_UPGRADED=$(opkg list-upgradable | cut -d ' ' -f1 | tr '\n' ' ')
if [ ! -z "$TO_BE_UPGRADED" ]
then
  echo "Found some packages to be upgraded: $TO_BE_UPGRADED"
  opkg upgrade $TO_BE_UPGRADED
else
  echo "All packages up to date!"
fi
