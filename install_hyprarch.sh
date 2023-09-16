#!/usr/bin/env -S bash -e

# Fixing annoying issue that breaks GitHub Actions
# shellcheck disable=SC2001

# Cleaning the TTY.
clear

# Cosmetics (colours for text).
BOLD='\e[1m'
BRED='\e[91m'
BBLUE='\e[34m'  
BGREEN='\e[92m'
BYELLOW='\e[93m'
RESET='\e[0m'

# Pretty print (function).
info_print () {
    echo -e "${BOLD}${BGREEN}[ ${BYELLOW}•${BGREEN} ] $1${RESET}"
}

# Pretty print for input (function).
input_print () {
    echo -ne "${BOLD}${BYELLOW}[ ${BGREEN}•${BYELLOW} ] $1${RESET}"
}

# Alert user of bad input (function).
error_print () {
    echo -e "${BOLD}${BRED}[ ${BBLUE}•${BRED} ] $1${RESET}"
}

# Welcome screen.
echo -ne "${BOLD}${BYELLOW}
======================================================================

██╗  ██╗██╗   ██╗██████╗ ██████╗        █████╗ ██████╗  ██████╗██╗  ██╗
██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗      ██╔══██╗██╔══██╗██╔════╝██║  ██║
███████║ ╚████╔╝ ██████╔╝██████╔╝█████╗███████║██████╔╝██║     ███████║
██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗╚════╝██╔══██║██╔══██╗██║     ██╔══██║
██║  ██║   ██║   ██║     ██║  ██║      ██║  ██║██║  ██║╚██████╗██║  ██║
╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝      ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
                                                                       
======================================================================
${RESET}"
info_print "Welcome to the last part of installing Hypr-Arch!"

sleep 2

# Enable multilib for packages like Steam (function)
info_print "Enabling multilib"
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo pacman -Syu --noconfirm

# Cloning the dotfiles and wallpaper (function)
info_print "Cloning the dotfiles and moving them to ~/.config + adding the default wallpaper"
cd && git clone https://github.com/aCeTotal/hypr-arch.git >/dev/null
cd hypr-arch >/dev/null
cp -r dotfiles/* ~/.config >/dev/null
sudo mkdir -p /usr/share/wallpapers/
sudo cp dotfiles/wallpapers/* /usr/share/wallpapers/

# Installing the AUR-Helper YAY (function).
info_print "Installing the AUR-Helper - YAY"
git clone https://aur.archlinux.org/yay.git >/dev/null
cd yay && makepkg -si --noconfirm >/dev/null
cd .. && rm -rf yay >/dev/null
yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk >/dev/null

# Adding the current user to the input group (function)
info_print "Adding the $USER to the input group"
sudo gpasswd -a $USER input

# Installing systempackages (function)
info_print "Installing system packages!"
yay -Syu --noconfirm --needed sddm nfs-utils qt5-wayland qt5ct waybar-hyprland wofi xdg-desktop-portal-hyprland qt6-wayland qt6ct qt5-svg qt5-quickcontrols2 qt5-graphicaleffects gtk3 polkit-gnome pipewire pipewire-pulse pipewire-jack wireplumber jq network-manager-sstp sstp-client github-cli github-desktop-bin wl-clipboard cliphist timeshift wat-git rmlint rebuild-detector downgrade p7zip unrar rar zip unzip network-manager-applet blueman grim slurp pkgfile swappy linux-headers firewalld fail2ban swaybg ttf-jetbrains-mono-nerd papirus-icon-theme ttf-ms-fonts

info_print "Installing Gaming-related packages!"
yay -Syu --noconfirm --needed gamescope discord gamemode mangohud lutris wine-staging protonup-qt vulkan-tools xone-dkms piper

info_print "Please select the correct VULKAN-DRIVER for your GPU. DO NOT JUST RANDOMLY PRESS ENTER!"
sudo pacman -Syu steam

# Check if NVIDIA GPU is found
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
info_print "NVIDIA GPU FOUND! Installing nvidia-related packages!"  
   yay -Syu --noconfirm --needed nvidia-dkms libva libva-nvidia-driver hyprland-nvidia

info_print "Creating modprobe config for your Nvidia card for max performance and wayland support" 
   sudo mkdir -p /etc/modprobe.d
   sudo touch /etc/modprobe.d/nvidia.conf
   echo -e "\nMODULES=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)" | sudo tee -a /etc/mkinitcpio.conf >/dev/null
   
   sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<'TXT'
   options nvidia-drm modeset=1
   options nvidia NVreg_UsePageAttributeTable=1
   options nvidia NVreg_EnablePCIeGen3=1
   options nvidia NVreg_EnableResizableBar=1
   options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x3; PowerMizerDefault=0x3; PowerMizerDefaultAC=0x3"
TXT
   
   sudo mkinitcpio -P

   # Adding Pacman hook to update initramfs after Nvidia driver upgrade
info_print "Creating Pacman hook to automatically update initramfs after every nvidia-driver upgrade" 
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

   echo -e "\nMODULES=(btrfs)" | sudo tee -a /etc/mkinitcpio.conf >/dev/null
   sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/g' /etc/default/grub 
   sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

info_print "Installing some nice packages"
yay -Syu --noconfirm --needed alacritty opera rider blender pureref gimp libreoffice-still dropbox spotify ventoy-bin

# Citrix Workspace.
input_print "Do you want to install the Citrix Workspace client? [y/N]?: "
read -r citrix_response
if [[ "${citrix_response,,}" =~ ^(yes|y)$ ]]; then
info_print "Installing the Citrix Workspace client"
yay -Syu icaclient --noconfirm >/dev/null
mkdir -p ~/.ICACLIENT/cache/ >/dev/null

sudo sed -i 's/TWIMode=*/TWIMode=0/g' /opt/Citrix/ICAClient/config/All_Regions.ini 
sudo sed -i 's/DesiredColor=*/DesiredColor=8/g' /opt/Citrix/ICAClient/config/All_Regions.ini
sudo sed -i 's/DesiredHRES=*/DesiredHRES=1024/g' /opt/Citrix/ICAClient/config/All_Regions.ini
sudo sed -i 's/DesiredVRES=*/DesiredVRES=768/g' /opt/Citrix/ICAClient/config/All_Regions.ini  
sudo sed -i 's/UseFullScreen=*/UseFullScreen=false/g' /opt/Citrix/ICAClient/config/All_Regions.ini  
sudo sed -i 's/TWIFullScreenMode=*/TWIFullScreenMode=false/g' /opt/Citrix/ICAClient/config/All_Regions.ini  
sudo sed -i 's/NoWindowManager=*/NoWindowManager=false/g' /opt/Citrix/ICAClient/config/All_Regions.ini

sudo mkdir -p /usr/share/applications/
sudo touch /usr/share/applications/wfica.desktop
sudo tee /usr/share/applications/wfica.desktop > /dev/null <<'TXT'
[Desktop Entry]
Name=Citrix ICA client
Comment="Launch Citrix applications from .ica files"
Categories=Network;
Exec=/opt/Citrix/ICAClient/wfica
Terminal=false
Type=Application
NoDisplay=true
MimeType=application/x-ica;

TXT
else
   input_print "Continuing the installation of Hypr-Arch!"
fi

# Adding theme for SDDM
input_print "Installing the SDDM Theme - Deepin"
git clone https://github.com/ArtemSmaznov/SDDM-themes.git
cd SDDM-themes
sudo cp -r deepin/ /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d/
sudo cp /usr/lib/sddm/sddm.conf.d/default.conf /etc/sddm.conf.d/default.conf
sudo sed -i "s/^Current=/Current=deepin/g" /etc/sddm.conf.d/default.conf

# Enable services
input_print "Enabling services"
sudo systemctl enable bluetooth.service
sudo systemctl enable sddm
sudo systemctl enable firewalld.service # https://wiki.archlinux.org/title/Firewalld
sudo systemctl enable fail2ban.service # https://wiki.archlinux.org/title/Fail2ban

# Creating the Hyprland wayland session
sudo mkdir -p /usr/share/wayland-sessions
echo -e "[Desktop Entry]\nName=Hyprland\nComment=An intelligent dynamic tiling Wayland compositor\nExec=Hyprland\nType=Application" | sudo tee -a /usr/share/wayland-sessions/hyprland.conf >/dev/null

# NFS shares
input_print "Do you want to add some NFS shares? [y/N]?: "
read -r nfs_response1
if [[ "${nfs_response1,,}" =~ ^(yes|y)$ ]]; then
  input_print "Type the server path for the first one. eg. 192.168.0.40:/bigdisk1 : "
  read -r servershare1
  input_print "Choose a name of the mounting folder: eg. bigdisk1 :"
  read -r mountfolder1
  sudo mkdir -p /mnt/$mountfolder1
  sudo chmod go=rwx /mnt/$mountfolder1 && sudo chown $USER: /mnt/$mountfolder1
  echo -e "\n#NFS\n$servershare1        /mnt/$mountfolder1       nfs     rw,defaults,noauto,nofail,users,x-systemd.automount,x-systemd.device-timeout=30,_netdev 0 0" | sudo tee -a /etc/fstab >/dev/null
  input_print "NFS share added to fstab! Do you want to add another one? [y/N]?: "
  read -r nfs_response2
fi

if [[ "${nfs_response2,,}" =~ ^(yes|y)$ ]]; then
  input_print "Type the server path for the second one. eg. 192.168.0.40:/bigdisk2 : "
  read -r servershare2
  input_print "Choose a name of the mounting folder: eg. bigdisk2 : "
  read -r mountfolder2
  sudo mkdir -p /mnt/$mountfolder2
  sudo chmod go=rwx /mnt/$mountfolder2 && sudo chown $USER: /mnt/$mountfolder2
  echo -e "\n\n$servershare2        /mnt/$mountfolder2       nfs     rw,defaults,noauto,nofail,users,x-systemd.automount,x-systemd.device-timeout=30,_netdev 0 0" | sudo tee -a /etc/fstab >/dev/null
  input_print "NFS share added to fstab! Do you want to add another one? [y/N]?: "
  read -r nfs_response3
fi

if [[ "${nfs_response3,,}" =~ ^(yes|y)$ ]]; then
  input_print "Type the server path for the second one. eg. 192.168.0.40:/bigdisk2 : "
  read -r servershare3
  input_print "Choose a name of the mounting folder: eg. bigdisk2 : "
  read -r mountfolder3
  sudo mkdir -p /mnt/$mountfolder3
  sudo chmod go=rwx /mnt/$mountfolder3 && sudo chown $USER: /mnt/$mountfolder3
  echo -e "\n\n$servershare3        /mnt/$mountfolder3       nfs     rw,defaults,noauto,nofail,users,x-systemd.automount,x-systemd.device-timeout=30,_netdev 0 0" | sudo tee -a /etc/fstab >/dev/null
  input_print "NFS share added to fstab! If you want to add more shares, please manually add them in /etc/fstab: "
else
   input_print "Continuing the installation of Hypr-Arch..."
fi

# Cursor Theme
input_print "Changing the cursor theme to: Bibata-Modern-Ice"
sudo rm /usr/share/icons/default/index.theme
sudo touch /usr/share/icons/default/index.theme
sudo tee /usr/share/icons/default/index.theme > /dev/null <<'TXT'
[icon theme] 
Inherits=Bibata-Modern-Ice
TXT

# Adding some aliases
input_print "Adding some aliases, like update (Safely updates the system) or install <package>"
rm ~/.bashrc && touch ~/.bashrc
~/.bashrc > /dev/null <<'TXT'
 #
 # ~/.bashrc
 #
 
 # If not running interactively, don't do anything
 [[ $- != *i* ]] && return
 
 alias ls='ls -lah --color=auto'
 alias l.='ls -d .* --color=auto'
 alias grep='grep --color=auto'
 alias update='sudo pacman-key --init && sudo pacman-key --populate && sudo pacman -Sy archlinux-keyring --noconfirm && sudo pacman -Su && yay -Syu'
 alias install='yay -Syu'
 alias c='clear'
 alias diff='colordiff'
 alias mount='mount |column -t'
 
 alias hyprconf='vim ~/.config/hypr/hyprland.conf'
 alias .config='cd ~/.config'
 
 ## a quick way to get out of current directory ##
 alias ..='cd ..'
 alias ...='cd ../../../'
 alias ....='cd ../../../../'
 alias .....='cd ../../../../../'
 PS1='[\u@\h \W]\$ '
 
 source /usr/share/doc/pkgfile/command-not-found.bash
TXT
source ~/.bashrc

# Installing informant last because it is destroying my autoinstall script.
input_print "Installing the package - Informant."
yay -Syu --noconfirm informant
sudo gpasswd -a $USER informant

# Removing install files and reboot the system
input_print "REBOOTING THE SYSTEM!"
rm -rf ~/hypr-arch
reboot
