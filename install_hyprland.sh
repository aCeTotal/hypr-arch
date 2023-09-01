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

# Clear the TTY
clear

# Install Packages
yay -Syu --noconfirm \
sddm qt5-wayland qt5ct waybar wofi xdg-desktop-portal-hyprland qt6-wayland qt6ct qt5-svg qt5-quickcontrols2 qt5-graphicaleffects gtk3 \
polkit-gnome pipewire pipewire-pulse pipewire-jack wireplumber jq wl-clipboard cliphist timeshift wat-git rmlint rebuild-detector downgrade \
python-requests pacman-contrib lxappearance file-roller gvfs thunar thunar-archive-plugin bluez bluez-utils pavucontrol pamixer btop mpv \
network-manager-applet blueman grim slurp swappy linux-headers \
steam gamescope discord gamemode mangohud lutris wine-staging protonup-qt \
alacritty brave-bin rider blender gimp \
icaclient nfs-utils network-manager-sstp sstp-client \
ttf-jetbrains-mono-nerd papirus-icon-theme \

# Disable WIFI Powersave
echo -e "[connection]\nwifi.powersave = 2" | sudo tee -a /etc/NetworkManager/conf.d/wifi-powersave.conf
sudo systemctl restart NetworkManager

# Check if NVIDIA GPU is found
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
   yay -Syu --noconfirm nvidia-dkms libva libva-nvidia-driver hyprland-nvidia

   sudo mkdir -p /etc/modprobe.d
   sudo touch /etc/modprobe.d/nvidia.conf
   echo -e "\nMODULES=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)" | sudo tee -a /etc/mkinitcpio.conf
   echo -e "options nvidia-drm modeset=1\noptions nvidia NVreg_UsePageAttributeTable=1\noptions nvidia NVreg_EnableResizableBar=1\noptions nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x3; PowerMizerDefault=0x3; PowerMizerDefaultAC=0x3"" | sudo tee -a /etc/modprobe.d/nvidia.conf
   sudo mkinitcpio -P

   # Adding Pacman hook to update initramfs after Nvidia driver upgrade
   echo -e "[Trigger]\nOperation=Install\nOperation=Upgrade\nOperation=Remove\nType=Package\nTarget=nvidia-dkms\nTarget=usr/lib/modules/*/vmlinuz\n\n[Action]\nDescription=Update NVIDIA module in initcpio\nDepends=mkinitcpio\nWhen=PostTransaction\nNeedsTargets\nExec=/bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'" | sudo tee -a /etc/pacman.d/hooks/nvidia.hook

   sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nvidia_drm.modeset=1"/g' /etc/default/grub
   sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/g' /etc/default/grub 
   sudo grub-mkconfig -o /boot/grub/grub.cfg

else
   yay -Syu --noconfirm hyprland

   echo -e "\nMODULES=(btrfs)" | sudo tee -a /etc/mkinitcpio.conf
   sudo mkinitcpio -P
fi

# Adding theme for SDDM
git clone https://github.com/ArtemSmaznov/SDDM-themes.git
cd SDDM-themes
sudo cp -r deepin/ /usr/share/sddm/themes/
sudo sed -i "s/^Current=.*/Current=deepin/g" /etc/sddm.conf

# Enable services
sudo systemctl enable bluetooth.service
sudo systemctl enable sddm

# Creating the Hyprland wayland session
sudo mkdir -p /usr/share/wayland-sessions
echo -e "[Desktop Entry]\nName=Hyprland\nComment=An intelligent dynamic tiling Wayland compositor\nExec=Hyprland\nType=Application" | sudo tee -a /usr/share/wayland-sessions/hyprland.conf

# Installing informant last because it is destroying my autoinstall script.
yay -Syu informant

# Removing install files and reboot the system
cd && rm -rf hypr-arch
reboot


