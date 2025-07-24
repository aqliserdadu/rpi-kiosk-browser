#!/bin/bash
# ================================
# Hapus Mode Kiosk dan Kembalikan ke Desktop GUI
# ================================

USERNAME="pi"
TTY="tty1"

echo "🧹 Menghapus konfigurasi kiosk..."

# 1. Hapus ~/.xinitrc
if [ -f "/home/$USERNAME/.xinitrc" ]; then
  echo "🗑️ Menghapus ~/.xinitrc..."
  rm "/home/$USERNAME/.xinitrc"
fi

# 2. Hapus autostart startx di ~/.bash_profile
if grep -q "startx" "/home/$USERNAME/.bash_profile"; then
  echo "🗑️ Menghapus autostart startx di ~/.bash_profile..."
  sed -i '/startx/,+3d' "/home/$USERNAME/.bash_profile"
fi

# 3. Hapus konfigurasi autologin systemd custom
AUTOLOGIN_DIR="/etc/systemd/system/getty@${TTY}.service.d"
if [ -d "$AUTOLOGIN_DIR" ]; then
  echo "🗑️ Menghapus konfigurasi autologin systemd..."
  sudo rm -r "$AUTOLOGIN_DIR"
fi

# 4. Kembalikan boot ke Desktop GUI (autologin)
echo "🔧 Mengatur boot ke Desktop GUI autologin..."
sudo raspi-config nonint do_boot_behaviour B4

# 5. Reload systemd
echo "🔄 Reload systemd daemon..."
sudo systemctl daemon-reexec

# 6. Informasi akhir
echo "✅ Kiosk mode telah dihapus dan sistem akan boot ke desktop GUI."

# Reboot prompt
read -p "Ingin reboot sekarang? [Y/n]: " confirm
confirm=${confirm,,}  # tolower
if [[ "$confirm" == "y" || -z "$confirm" ]]; then
  echo "♻️ Rebooting..."
  sudo reboot
else
  echo "ℹ️ Silakan reboot manual dengan perintah: sudo reboot"
fi
