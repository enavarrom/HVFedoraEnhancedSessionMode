#!/bin/bash

# Actualiza el sistema
sudo dnf update -y

# Instala las herramientas necesarias para Hyper-V
sudo dnf install -y hyperv-daemons xrdp tigervnc-server

# Habilita y arranca los servicios de Hyper-V
sudo systemctl enable hypervvssd.service --now
sudo systemctl enable hypervfcopyd.service --now
sudo systemctl enable hypervkvpd.service --now

# Habilita y arranca el servicio de XRDP
sudo systemctl enable xrdp --now

# Añade el usuario 'xrdp' al grupo 'ssl-cert' para acceso RDP
sudo usermod -aG xrdp $(whoami)

# Permite conexiones en el firewall (si está activo)
sudo firewall-cmd --permanent --add-port=3389/tcp
sudo firewall-cmd --reload

# Configura SDDM para aceptar sesiones RDP
echo "[Xdmcp]
Enable=true" | sudo tee -a /etc/sddm.conf

# Configura el archivo de configuración de XRDP para usar Xorg como backend de sesión
echo "use_vsock=true" | sudo tee -a /etc/xrdp/xrdp.ini

# Reinicia XRDP para aplicar los cambios
sudo systemctl restart xrdp

echo "Configuración de Enhanced Session para Hyper-V en Fedora 40 KDE completada."
