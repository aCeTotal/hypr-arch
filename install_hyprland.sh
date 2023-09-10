#!/bin/bash
#
# A Simple script to install [aCe]Total's version of Arch Linux with Hyprland. 
#

# Install Yay
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si --noconfirm
cd .. && rm -rf yay
yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk

# Enable Multilib
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo pacman -Syu --noconfirm

# Adding the dotfiles
cp -r dotfiles/* ~/.config

# Moving default wallpaper to /usr/share/wallpapers
sudo mkdir -p /usr/share/wallpapers/
sudo cp dotfiles/wallpapers/* /usr/share/wallpapers/

# Adding the user to the input group
sudo gpasswd -a lars input

# Clear the TTY
clear

# Install Packages
yay -Syu --noconfirm \
sddm qt5-wayland qt5ct waybar wofi xdg-desktop-portal-hyprland qt6-wayland qt6ct qt5-svg qt5-quickcontrols2 qt5-graphicaleffects gtk3 \
polkit-gnome pipewire swaybg pipewire-pulse pipewire-jack wireplumber jq wl-clipboard cliphist timeshift wat-git rmlint rebuild-detector downgrade p7zip unrar zip unzip \
python-requests pacman-contrib lxappearance file-roller gvfs thunar thunar-archive-plugin bluez bluez-utils pavucontrol pamixer btop mpv \
network-manager-applet blueman grim slurp swappy linux-headers firewalld fail2ban \
gamescope discord gamemode mangohud lutris wine-staging protonup-qt vulkan-tools xone-dkms \
alacritty firefox rider blender pureref gimp \
icaclient nfs-utils network-manager-sstp sstp-client github-cli github-desktop-bin \
ttf-jetbrains-mono-nerd papirus-icon-theme \
# kodi retroarch retroarch-assets-xmb \

# Disable WIFI Powersave
sudo touch /etc/NetworkManager/conf.d/wifi-powersave.conf
echo -e "[connection]\nwifi.powersave = 2" | sudo tee -a /etc/NetworkManager/conf.d/wifi-powersave.conf
sudo systemctl restart NetworkManager

# Manual confirm Steam to Choose the correct Vulkan package.
echo "SELECT THE CORRECT VULKAN-DRIVER!"
echo "SELECT THE CORRECT VULKAN-DRIVER!"
echo "SELECT THE CORRECT VULKAN-DRIVER!"
echo "SELECT THE CORRECT VULKAN-DRIVER!"
sudo pacman -Syu steam

# Check if NVIDIA GPU is found
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
   yay -Syu --noconfirm nvidia-dkms libva libva-nvidia-driver hyprland-nvidia

   sudo mkdir -p /etc/modprobe.d
   sudo touch /etc/modprobe.d/nvidia.conf
   echo -e "\nMODULES=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)" | sudo tee -a /etc/mkinitcpio.conf
   
   sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<'TXT'
   options nvidia-drm modeset=1
   options nvidia NVreg_UsePageAttributeTable=1
   options nvidia NVreg_EnablePCIeGen3=1
   options nvidia NVreg_EnableResizableBar=1
   options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x3; PowerMizerDefault=0x3; PowerMizerDefaultAC=0x3"
TXT
   
   sudo mkinitcpio -P

   # Adding Pacman hook to update initramfs after Nvidia driver upgrade
   sudo tee /etc/pacman.d/hooks/nvidia.hook > /dev/null <<'TXT'
  [Trigger]
  Operation=Install
  Operation=Upgrade
  Operation=Remove
  Type=Package
  Target=nvidia-dkms
  Target=linux-zen

  [Action]
  Description=Update NVIDIA module in initcpio
  Depends=mkinitcpio
  When=PostTransaction
  NeedsTargets
  Exec=/bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
TXT

   sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nvidia_drm.modeset=1"/g' /etc/default/grub
   sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/g' /etc/default/grub 
   sudo grub-mkconfig -o /boot/grub/grub.cfg

else
   yay -Syu --noconfirm hyprland

   echo -e "\nMODULES=(btrfs)" | sudo tee -a /etc/mkinitcpio.conf
   sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/g' /etc/default/grub 
   sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# Adding theme for SDDM
git clone https://github.com/ArtemSmaznov/SDDM-themes.git
cd SDDM-themes
sudo cp -r deepin/ /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d/
sudo cp /usr/lib/sddm/sddm.conf.d/default.conf /etc/sddm.conf.d/default.conf
sudo sed -i "s/^Current=/Current=deepin/g" /etc/sddm.conf.d/default.conf

# Enable services
sudo systemctl enable bluetooth.service
sudo systemctl enable sddm
sudo systemctl enable firewalld.service # https://wiki.archlinux.org/title/Firewalld
sudo systemctl enable fail2ban.service # https://wiki.archlinux.org/title/Fail2ban

# Creating the Hyprland wayland session
sudo mkdir -p /usr/share/wayland-sessions
echo -e "[Desktop Entry]\nName=Hyprland\nComment=An intelligent dynamic tiling Wayland compositor\nExec=Hyprland\nType=Application" | sudo tee -a /usr/share/wayland-sessions/hyprland.conf

# Adding NFS Shares and creating Cache-folder for ICACLIENT
sudo mkdir -p ~/.ICACLIENT/cache
sudo mkdir -p /mnt/14tb
sudo go=rwx /mnt/14tb && sudo chown lars: /mnt/14tb
echo -e "#NFS\n192.168.0.40:/bigdisk1        /mnt/14tb       nfs     rw,defaults,noauto,nofail,users,x-systemd.automount,x-systemd.device-timeout=30,_netdev 0 0" | sudo tee -a /etc/fstab

# Installing informant last because it is destroying my autoinstall script.
yay -Syu --noconfirm informant

# Removing install files and reboot the system
cd && rm -rf hypr-arch
reboot


