#!/bin/bash
# Install Hyper-V Enhanced Session Mode on Fedora 30

# Load the Hyper-V kernel module

sudo dnf remove -y xrdp xrdp-selinux
sudo dnf install -y xrdp

SESMAN_FILE="/etc/pam.d/xrdp-sesman"

# Create a backup of the original file
cp $SESMAN_FILE ${SESMAN_FILE}.bak

# Use sed to perform the commenting and uncommenting
sed -i.bak \
    -e '/auth\s\+include\s\+password-auth/s/^/#/' \
    -e '/account\s\+include\s\+password-auth/s/^/#/' \
    -e '/password\s\+include\s\+password-auth/s/^/#/' \
    -e '/session\s\+include\s\+password-auth/s/^/#/' \
    -e '/#auth\s\+include\s\+gdm-password/s/^#//' \
    -e '/#account\s\+include\s\+gdm-password/s/^#//' \
    -e '/#password\s\+include\s\+gdm-password/s/^#//' \
    -e '/#session\s\+include\s\+gdm-password/s/^#//' \
    "$SESMAN_FILE"

# Configure xrdp
sudo sed -i "/^port=3389/c\port=vsock://-1:3389" /etc/xrdp/xrdp.ini
sudo sed -i "/^security_layer=.*/c\security_layer=rdp" /etc/xrdp/xrdp.ini
sudo sed -i "/^bitmap_compression=.*/c\bitmap_compression=false" /etc/xrdp/xrdp.ini

sudo systemctl enable xrdp xrdp-sesman




