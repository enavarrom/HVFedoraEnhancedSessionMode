#!/bin/bash
# Install Hyper-V Enhanced Session Mode on Fedora 30

# Remove old xrdp installation if present and install xrdp
sudo dnf remove -y xrdp xrdp-selinux
sudo dnf install -y xrdp startplasma-x11

SESMAN_FILE="/etc/pam.d/xrdp-sesman"
STARTWM_FILE="/etc/xrdp/startwm.sh"
SESMAN_INI_FILE="/etc/xrdp/sesman.ini"
POLKIT_RULES_FILE="/etc/polkit-1/rules.d/99-allow-reboot.rules"
GROUP_NAME="remote"

# Create a backup of the original xrdp-sesman file
cp $SESMAN_FILE ${SESMAN_FILE}.bak

# Use sed to comment and uncomment specific lines in xrdp-sesman
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

# Configure xrdp settings
sudo sed -i "/^port=3389/c\port=vsock://-1:3389" /etc/xrdp/xrdp.ini
sudo sed -i "/^security_layer=.*/c\security_layer=rdp" /etc/xrdp/xrdp.ini
sudo sed -i "/^bitmap_compression=.*/c\bitmap_compression=false" /etc/xrdp/xrdp.ini

# Create the startwm.sh file
cat << 'EOF' | sudo tee $STARTWM_FILE > /dev/null
#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Si estás usando KDE Plasma
if [ -r /etc/X11/Xsession ]; then
    exec /etc/X11/Xsession
else
    exec startplasma-x11
fi
EOF

# Make startwm.sh executable
sudo chmod +x $STARTWM_FILE

# Configure sesman.ini to use the new XSession
echo -e "[XSession]\nparam=/etc/xrdp/startwm.sh" | sudo tee -a $SESMAN_INI_FILE > /dev/null

# Create the Polkit rule for reboot and power-off
cat << 'EOF' | sudo tee $POLKIT_RULES_FILE > /dev/null
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.reboot" ||
        action.id == "org.freedesktop.login1.power-off") {
        if (subject.isInGroup("remote")) {
            return polkit.Result.YES;
        }
    }
});
EOF

# Create the remote group if it does not exist and add the current user to it
if ! getent group $GROUP_NAME > /dev/null; then
    sudo groupadd $GROUP_NAME
fi

sudo usermod -aG $GROUP_NAME $USER

# Enable and restart xrdp and xrdp-sesman services
sudo systemctl enable xrdp xrdp-sesman
sudo systemctl restart xrdp xrdp-sesman
