#!/bin/bash
# Install Hyper-V Enhanced Session Mode on Fedora 30

# Load the Hyper-V kernel module

sudo dnf update -y

sudo dnf remove -y xrdp xrdp-selinux plasma-workspace-x11
sudo dnf install -y xrdp plasma-workspace-x11

SESMAN_FILE="/etc/pam.d/xrdp-sesman"

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





