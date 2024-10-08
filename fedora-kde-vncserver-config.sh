#!/bin/bash


# Actualizar el sistema
sudo dnf update -y

# Instalar VNC y KDE Plasma
sudo dnf install -y tigervnc-server

# Verificar si startplasma-x11 está disponible
if ! command -v startplasma &> /dev/null; then
    echo "startplasma no está instalado. Instalando plasma-desktop..."
    sudo dnf install -y plasma-desktop
fi

# Crear un archivo de servicio para el servidor VNC
VNC_CONFIG="/etc/systemd/system/vncserver@:1.service"

# Crear el archivo de servicio
cat <<EOL | sudo tee $VNC_CONFIG
[Unit]
Description=Start TigerVNC server at startup
After=display-manager.service

[Service]
Type=simple
User=$USER
PIDFile=/home/$USER/.vnc/%H:%i.pid
ExecStart=/usr/bin/vncserver %i -geometry 1920x1080 -depth 24
ExecStop=/usr/bin/vncserver -kill %i

[Install]
WantedBy=multi-user.target
EOL

# Establecer la contraseña de VNC
echo "Por favor, establece la contraseña para la conexión VNC."
vncpasswd

# Crear el directorio ~/.vnc si no existe
mkdir -p ~/.vnc

# Crear y configurar el archivo ~/.vnc/xstartup
XSTARTUP_FILE="$HOME/.vnc/xstartup"
cat <<EOL > $XSTARTUP_FILE
#!/bin/sh

# Iniciar el entorno de escritorio KDE
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startplasma
EOL

# Hacer que el archivo xstartup sea ejecutable
chmod +x $XSTARTUP_FILE

# Permitir el puerto VNC en el firewall
sudo firewall-cmd --permanent --add-port=5901/tcp
sudo firewall-cmd --reload

# Habilitar y arrancar el servicio VNC
sudo systemctl enable vncserver@:1.service
sudo systemctl start vncserver@:1.service

echo "Logs del servidor VNC:"
cat ~/.vnc/*.log

echo "Configuración completa. Puedes conectarte a la máquina virtual usando un cliente VNC en la dirección: <tu_direccion_ip>:5901"
echo "También puedes conectarte mediante XRDP en el puerto 3389."
