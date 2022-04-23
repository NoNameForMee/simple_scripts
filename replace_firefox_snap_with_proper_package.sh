#!/bin/bash

# This script can be used to replace broken Firefox snap with a proper Firefox package provided by MozillaTeam's PPA.

# The main reason to use this script is to avoid having the broken Firefox snap version create a lot of garbage files in
# ~/Downloads/, such as the "~/Downloads/firefox.tmp", each and every time it gets started...

# Another way of doing it could be to simply hack the /snap/firefox/current/firefox.launcher which has a line reading
# export TMPDIR="$(xdg-user-dir DOWNLOAD)/firefox.tmp"
# This is the main bug causing the problem with "firefox.tmp" in the users DOWNLOAD folder.
# If "~/.config/user-dirs.dirs" is made to point the "DOWNLOAD" to "/tmp" then perhaps it would cause Firefox to place itself
# in a proper "/tmp/" sub folder... Or perhaps one must modify the Firefox snap itself, but that is a bit of a pain...

# An alternative would be to simply create an empty file without write permissions..
# touch ~/Downloads/firefox.tmp && chmod a-rwx ~/Downloads/firefox.tmp

# Effectively solves the bug https://bugzilla.mozilla.org/show_bug.cgi?id=1733750

sudo apt purge firefox && sudo snap remove firefox
sudo apt install apt-transport-https

# Ref for key is https://launchpad.net/~mozillateam/+archive/ubuntu/ppa which states
# "Signing key:
#    1024R/0AB215679C571D1C8325275B9BDB3D89CE49EC21
# Fingerprint:
#    0AB215679C571D1C8325275B9BDB3D89CE49EC21"
wget 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0ab215679c571d1c8325275b9bdb3d89ce49ec21' -O mozilla_ppa.key
# Verify manually that the output "mozilla_ppa.key" contains just one key starting with something like:
# -----BEGIN PGP PUBLIC KEY BLOCK-----
# Comment: Hostname: 
# Version: Hockeypuck ~unreleased
# 
# xo0ESXMwOwEEAL7UP143coSax/7/8UdgD+WjIoIxzqhkTeoGOyw/r2DlRCBPFAOH
### and so on...

# Then use "gpg" to convert it from ASCII to a Binary form (for usage with "apt")
gpg --import mozilla_ppa.key
gpg --export 9BDB3D89CE49EC21 > mozilla_ppa.gpg
# Nobody should be able to modify this key
chmod go-w mozilla_ppa.gpg
# Move the key to the keyrings folder
sudo mv mozilla_ppa.gpg /usr/share/keyrings/mozilla_ppa.gpg
# Owned by root, and only editable by root
sudo chown root:root /usr/share/keyrings/mozilla_ppa.gpg

# Write the apt source.list file
echo "deb [signed-by=/usr/share/keyrings/mozilla_ppa.gpg] https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/mozillateam-ppa.list

# In order for "apt" to always use the correct Mozilla Team PPA package and not the buggy Snap version, set a high priority for the PPA one.
# Write to a new file "/etc/apt/preferences.d/mozillateam-ppa"
cat <<EOF | sudo tee /etc/apt/preferences.d/mozillateam-ppa
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 501
EOF

# then finally install a proper Firefox which does not create a lot of ~/Downloads/firefox.tmp crap folders
sudo apt update && sudo apt install firefox
# possibly also "firefox-locale-{whatever}"
