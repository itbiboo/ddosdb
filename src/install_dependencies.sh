#!/bin/bash

# This script downloads and compiles a custom version of nfdump, which only anonymises the destination IP address. 
# Which can be found here: https://github.com/Koenvh1/nfdump.git

# It also adds support for reading pcap files, using the configure parameters
# The output executable will be generated as ./nfdump/bin/nfdump and ./nfdump/bin/nfanon.

# Make sure the current working directory is the directory this file is located in
# From https://stackoverflow.com/questions/3349105/how-to-set-current-working-directory-to-the-directory-of-the-script
cd "${0%/*}"

# Check whether the current user is the root user, exit otherwise
# From https://askubuntu.com/a/30157/8698

echo "=========== CREATING OUTPUT FOLDER ==========="
mkdir -p ./output
touch output/logs.log
echo "=========== CREATED OUTPUT FOLDER ==========="

echo "=========== INSTALLING DEPENDENCIES ==========="
if [ $(id -u) = 0 ]; then
    # User has root access
    if [ -n "$(command -v apt-get)" ]; then
        # For Debian-based distributions
        apt-get update
        apt-get -y install git libtool autoconf automake pkg-config flex bison libbz2-dev libpcap-dev bittwist tshark python3 python3-pip
    elif [ -n "$(command -v yum)" ]; then
        # For Red Hat-based distributions
        yum check-update
        yum -y install git libtool autoconf automake pkg-config flex bison bzip2-devel libpcap-devel bittwist tshark python python-pip
    elif [ -n "$(command -v dnf)" ]; then
        # For Fedora-based distributions
        dnf check-update
        dnf -y install git libtool autoconf automake pkg-config flex bison bzip2-devel libpcap-devel bittwist tshark python python-pip
    elif [ -n "$(command -v brew)" ]; then
        # For macOS-based distributions
        # possible solution for mac users not working the bittwist
        # ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null
        # then install it
        brew check-update
        brew -y install git libtool autoconf automake pkg-config flex bison bittwist tshark python python-pip
        brew -y install --devel bzip2 libpcap
    elif [ -n "$(command -v port)" ]; then
        # For macOS-based distributions
        port check-update
        port install git libtool autoconf automake pkgconfig flex bison zlib libpcap bittwist tshark python python-pip
    else 
        echo "Package manager yum, dnf, brew or apt-get not found!"
        exit 1;
    fi
    pip3 install --user pandas requests
else
    echo "Skip installing dependencies, because the script has no root access." >&2
fi

echo "=========== CLONING REPOSITORY ==========="
git clone https://github.com/Koenvh1/nfdump.git ../nfdump_modified

# Going into the just cloned repository
cd "../nfdump_modified"
echo "=========== GENERATING ==========="
/bin/sh ./autogen.sh

echo "=========== CONFIGURING ==========="
/bin/sh ./configure --enable-sflow --enable-readpcap --enable-nfpcapd

echo "=========== MAKING ==========="
make

echo "=========== INSTALLING ==========="
make install

echo "=========== CONFIGURE DYNAMIC LIBRARIES ==========="
ldconfig

echo "=========== SETTING PERMISSIONS ==========="
# Get the current user, and recursively set the permissions
out="$(who am i)"
# Get the first part only
name="$(echo $out | cut -d' ' -f1)"
chown $name:$name ./ -R

echo "Creating output folder."

echo "Done."
