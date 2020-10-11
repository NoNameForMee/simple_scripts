#!/bin/bash

# Script to automatically download the latest relases for Samsung Galaxy S5 "klte"
#  - Lineage OS ROM
#  - TWRP <- if $DONATED_TO_TWRP=="true"
#  - OpenGapps (Arm 10.0 nano) <- requires changing when LineageOS release new major versions.
#  - Weather provider
# And the verify the files are correct using the provided signatures (certificates, SHA256 and MD5).
# Author: NoNameForMee (github), 2017
# License: GNU GENERAL PUBLIC LICENSE, GPL-3.0-or-later
# Full text available at https://www.gnu.org/licenses/gpl-3.0.html

# SETUP
function initalize
{
  DONATED_TO_TWRP="false" # Change to true if you have donated and this script will download latest TWRP as well.
  cd ~/new_LineageOS/
  # Verify required tools
  for iDEPEND in "wget" "keytool" "gpg" "md5sum" "shasum"
   do
    command -v $iDEPEND >/dev/null 2>&1 || { echo >&2 "$iDEPEND is required by this scripts. Aborting."; exit 1; }
  done
}

# Help functions
function lineageos
{
  # Get link to first (latest) released zip of Lineage OS
  fileLink=$(wget -qO- https://download.lineageos.org/klte | grep -m 1 "klte-signed.zip" | cut -d '"' -f 2)
  fileName="${fileLink##*/}"
  # Download zip, if it does not already exist in path
  wget -q -nc $fileLink -O $fileName
  # Get corresponding SHA256 file
  wget -q -nc $fileLink?sha256 -O $fileName".sha256"
  # Cryptographic verification of signature. Grep for the SHA-256 checksum of certificate used to sign zip. 
  # Source: https://wiki.lineageos.org/verifying-builds.html
  #  and/or https://github.com/lineageos/lineage_wiki/blob/master/pages/meta/verifying_builds.md
  echo "Checking certificate of $fileName"
  # ~/git_repos/update_verifier/ contains the git repo https://github.com/LineageOS/update_verifier
  python3 ~/git_repos/update_verifier/update_verifier.py ~/git_repos/update_verifier/lineageos_pubkey $fileName
  fileLink=$(wget -qO- https://download.lineageos.org/klte | grep -m 1 "recovery-klte.img" | cut -d '"' -f 2)
  fileName="${fileLink##*/}"
  # Download zip, if it does not already exist in path
  wget -q -nc $fileLink -O $fileName
  # Get corresponding SHA256 file
  wget -q -nc $fileLink?sha256 -O $fileName".sha256"
}

function opengapps
{
  # GApps (use Github's API to determine latest release for the ARM build)
  # then grep only version for 10.0 Nano.
  # FIXME: This must be changed when LineageOS upgrade to new major version (change 7.1 to 8.1 etc)
  # tmp=$(wget -qO- https://api.github.com/repos/opengapps/arm/releases/latest | \
  #  grep -o 'https\://github\.com/opengapps/arm/releases/download/[[:digit:]]\{8,\}/open_gapps-arm-10.0-nano-[[:digit:]]\{8,\}\.zi\(p\|p\.md5\)')
  # 2019/08/26 MOVE TO:  https://sourceforge.net/projects/opengapps/rss?path=/arm
  fileLink=$(wget -qO- "https://sourceforge.net/projects/opengapps/rss?path=/arm" | \
    grep -o 'url="https\://sourceforge\.net/projects/opengapps/files/arm/[[:digit:]]\{8,\}/open_gapps-arm-10.0-nano-[[:digit:]]\{8,\}\.zip/download' | cut -c6- -)
  # Get zip file
  fileName=$(echo $fileLink | grep -o 'open_gapps-arm-10.0-nano-[[:digit:]]\{8,8\}.zip')
  wget -q -nc $fileLink -O $fileName
  # Append ".md5" to the end of the filename inside the fileLink
  fileLinkMD5=$(echo $fileLink | sed 's/\<zip\>/&.md5/')
  wget -q -nc $fileLinkMD5 -O $fileName".md5"
  # Cryptographic verification of signature. Grep for the SHA-256 checksum. 
  # Source: https://github.com/opengapps/opengapps/issues/119#issuecomment-322305081
  # fileName="${fileLink##*/}"
  # remove trailing whitespace characters
  # fileName="${fileName%"${fileName##*[![:space:]]}"}" 
  echo "Checking certificate of $fileName"
  if keytool -printcert -jarfile $fileName | \
    grep -q "07:64:B6:43:15:96:FA:94:5C:68:E5:BD:D8:A8:30:5E:2F:2C:97:78:90:C1:CC:87:DB:E5:4A:90:0E:B2:61:12"; then
    echo "File: $fileName was OK. Found the expected certificates SHA256 hash.";
  else
    echo >&2 "File: $fileName was NOT ok. Requires manual check.";
  fi
  sha256sum $fileName > $fileName".sha256"
}

function twrp
{
  # Get link to first (latest) released verison of TWRP
  tmp=$(wget -qO- https://dl.twrp.me/klte/ | \
    grep -m 1 -o '/klte/twrp-[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}-[[:digit:]]\{1,\}-klte\.img\.html')
  # Download released file, its asc and md5, using referer as to avoid problem with TWRP servers
  # https://github.com/TeamWin/Team-Win-Recovery-Project/issues/625
  wget -q -nc -e robots=off -nd -r -l1 -R "${tmp##*/}*" --referer=https://dl.twrp.me$tmp https://dl.twrp.me$tmp
  tmp="${tmp%.html}"
  fileName="${tmp##*/}"
  # Verify signature (import public key separatly).
  echo "Checking GPG signing of $fileName"
  gpg --verify $fileName.asc $fileName
}

function weatherprovider
{
  # Weather provider
  # Static links to latest release? (appears to not keep older versions)
  fileName="OpenWeatherProvider-16.0-signed.apk" # <- My preferred provider
  fileLink=$(wget -qO- https://download.lineageos.org/extras | grep -m 1 $fileName | cut -d '"' -f 2)
  # Download zip, if it does not already exist in path
  wget -q -nc $fileLink -O $fileName
  # Get corresponding SHA256 file
  wget -q -nc $fileLink?sha256 -O $fileName".sha256"
}

function verifydownloads
{
  # Verify the MD5 & SHA256 checksums.
  # NOTE: Some duplicated result as we have manually created a couple of the MD5 sums...
  echo "Checking MD5 and SHA256 checksums"
  md5sum -c ./*.md5
  shasum -c ./*.sha256
}

################
#
# MAIN PROGRAM
#
################
initalize
lineageos
opengapps
[ $DONATED_TO_TWRP == "true" ] && twrp
weatherprovider
verifydownloads

echo "Now ready for upgrading phone. Transfer packages and their .sha256 files to the phone, reboot it into recovery and flash."
#echo "Now ready for upgrading phone. Transfer packages and their .md5 files to the phone, reboot it into recovery mode and flash."
