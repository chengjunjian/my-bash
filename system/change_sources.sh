#!/bin/bash

# A script to change Ubuntu sources to a domestic mirror (aliyun).
#
# Author: Gemini
# Version: 1.0
#
# Usage:
#   1. Save this script as change_sources.sh
#   2. Run: chmod +x change_sources.sh
#   3. Run: sudo ./change_sources.sh

set -e

#  ^n  ^o^v Ubuntu  ^i^h ^|     ^o 
CODENAME=$(lsb_release -cs)

#   ^g    ^n  ^|^i ^z^d sources.list  ^v^g   
echo "Backing up /etc/apt/sources.list to /etc/apt/sources.list.bak..."
if [ -f /etc/apt/sources.list ]; then
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
else
    echo "/etc/apt/sources.list not found. Creating a new one."
fi

#  ^h^{    ^v  ^z^d sources.list  ^v^g     ^l    ^t  ^x  ^g^l  ^q ^u^| ^c^o
echo "Writing new sources.list for Ubuntu ${CODENAME} using Aliyun mirror..."
sudo tee /etc/apt/sources.list > /dev/null <<EOF
# Aliyun Mirror for Ubuntu
deb https://mirrors.aliyun.com/ubuntu/ ${CODENAME} main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ ${CODENAME}-backports main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ ${CODENAME}-security main restricted universe multiverse

#deb-src https://mirrors.aliyun.com/ubuntu/ ${CODENAME} main restricted universe multiverse
#deb-src https://mirrors.aliyun.com/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
#deb-src https://mirrors.aliyun.com/ubuntu/ ${CODENAME}-backports main restricted universe multiverse
#deb-src https://mirrors.aliyun.com/ubuntu/ ${CODENAME}-security main restricted universe multiverse
EOF

#  ^{  ^v        ^l^e ^h^w   
echo "Updating package list..."
sudo apt-get update

