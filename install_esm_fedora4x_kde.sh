#!/bin/bash
# Install Hyper-V Enhanced Session Mode on Fedora 30

# Load the Hyper-V kernel module

sudo dnf update -y

sudo dnf remove -y xrdp xrdp-selinux plasma-workspace-x11
sudo dnf install -y xrdp plasma-workspace-x11

SESMAN_FILE="/etc/pam.d/xrdp-sesman"

# Create a backup of the original file
sudo cp $SESMAN_FILE ${SESMAN_FILE}.bak

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

# Create the startwm.sh file
STARTWM_FILE="/etc/xrdp/startwm.sh"
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
SESMAN_INI_FILE="/etc/xrdp/sesman.ini"

echo -e "[XSession]\nparam=/etc/xrdp/startwm.sh" | sudo tee -a $SESMAN_INI_FILE > /dev/null

# Create the Polkit rule for reboot and power-off
POLKIT_RULES_FILE="/etc/polkit-1/rules.d/99-allow-reboot.rules"

cat << 'EOF' | sudo tee $POLKIT_RULES_FILE > /dev/null
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.reboot" ||
        action.id == "org.freedesktop.login1.power-off") {
        if (subject.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    }
});
EOF

sudo systemctl restart xrdp xrdp-sesman polkit





