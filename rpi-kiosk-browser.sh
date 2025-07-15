#!/bin/bash
# ================================
# Setup Raspberry Pi Kiosk Mode Browser
# ================================

# ===== Default Values =====
DEFAULT_URL="http://localhost:5010"
DEFAULT_USER="pi"
DEFAULT_TTY="tty1"
CHROMIUM_FLAGS="--noerrdialogs --disable-infobars --disable-session-crashed-bubble --kiosk"

# ===== Prompt for Input =====
echo "🌐 Masukkan URL Kiosk (default: $DEFAULT_URL):"
read -r URL_KIOSK
URL_KIOSK=${URL_KIOSK:-$DEFAULT_URL}

echo "👤 Masukkan username Raspberry Pi (default: $DEFAULT_USER):"
read -r USERNAME
USERNAME=${USERNAME:-$DEFAULT_USER}

echo "📺 Menggunakan TTY: $DEFAULT_TTY"

# ===== Install Required Packages =====
echo "🛠️ Memastikan paket sudah ter-update..."
sudo apt update && sudo apt install --no-install-recommends -y \
  xserver-xorg x11-xserver-utils xinit openbox chromium-browser

echo "✅ Paket X11, Openbox, Chromium sudah terinstall."

# ===== Configure Autologin =====
echo "🛠️ Mengatur autologin ke console..."
sudo raspi-config nonint do_boot_behaviour B2  # console autologin

echo "🛠️ Mengaktifkan autologin systemd di $DEFAULT_TTY..."
sudo mkdir -p /etc/systemd/system/getty@${DEFAULT_TTY}.service.d
sudo tee /etc/systemd/system/getty@${DEFAULT_TTY}.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF

echo "✅ Autologin aktif."

# ===== Create ~/.xinitrc =====
echo "🧾 Membuat file ~/.xinitrc..."
cat <<EOF > /home/$USERNAME/.xinitrc
#!/bin/bash
xset -dpms
xset s off
xset s noblank
openbox-session &
sleep 5
chromium-browser $CHROMIUM_FLAGS "$URL_KIOSK"
EOF

chmod +x /home/$USERNAME/.xinitrc
chown $USERNAME:$USERNAME /home/$USERNAME/.xinitrc

# ===== Add Auto-startx =====
echo "🧾 Menambahkan auto-startx ke ~/.bash_profile..."
cat <<EOF >> /home/$USERNAME/.bash_profile

# Start X on $DEFAULT_TTY for kiosk
if [ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/$DEFAULT_TTY" ]; then
  startx
fi
EOF

chown $USERNAME:$USERNAME /home/$USERNAME/.bash_profile

# ===== Reboot Prompt =====
echo "✅ Selesai. Sistem akan reboot untuk uji coba."
read -p "Ingin langsung reboot? [Y/n]: " confirm
confirm=\${confirm,,}  # tolower
if [[ "\$confirm" == "y" || -z "\$confirm" ]]; then
  sudo reboot
else
  echo "➡️  Silakan reboot manual dengan perintah: sudo reboot"
fi
