#!/usr/bin/env -S bash -e

# Cleaning the TTY.
sudo pacman -Sy &>/dev/null
sudo pacman-key --init  &>/dev/null
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

install_yay () {
    info_print "Installing the AUR-helper - Yay."
    git clone https://aur.archlinux.org/yay-git.git ~/yay-git &>/dev/null
    cd ~/yay-git &>/dev/null
    makepkg -si --noconfirm &>/dev/null
    cd && rm -rf ~/yay-git &>/dev/null
    return 0;
}

enabling_multilib () {
    info_print "Enabling multilib."
    sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf &>/dev/null
    sudo pacman -Syu --noconfirm &>/dev/null
    return 0;
}

clone_dotfiles () {
    info_print "Cloning the dotfiles and creating symbolic links."

    REPO_URL="https://github.com/aCeTotal/arch_dotfiles.git"
    CLONE_DIR="$HOME/.dotrepo"
    DOTFILES_DIR="$CLONE_DIR/dotfiles"
    TARGET_DIR="$HOME/.config"

    git clone "$REPO_URL" "$CLONE_DIR" &>/dev/null

    if [ $? -ne 0 ]; then
         echo "The cloning failed!"
        exit 1
    fi

    if [ -d "$TARGET_DIR" ]; then
        rm -rf "$TARGET_DIR"/*
    else
        mkdir -p "$TARGET_DIR"
    fi

    for item in "$DOTFILES_DIR"/*; do
        itemname=$(basename "$item")
        ln -sfn "$item" "$TARGET_DIR/$itemname"
    done
}

usergroups () {
    info_print "Adding user $USER to the input group"
    sudo gpasswd -a $USER wheel input &>/dev/null
    return 0;
}

nvidia_check () {
    if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
        info_print "NVIDIA GPU FOUND! Installing nvidia-related packages."
        sudo pacman -Syu --noconfirm --needed nvidia-dkms cuda libva-nvidia-driver nvidia-utils lib32-nvidia-utils &>/dev/null

        info_print "Creating modprobe config for your Nvidia card for max performance and wayland support." 
        sudo mkdir -p /etc/modprobe.d &>/dev/null
        sudo touch /etc/modprobe.d/nvidia.conf &>/dev/null
        echo -e "" | sudo tee -a /etc/mkinitcpio.conf
        echo -e "\nMODULES=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)" | sudo tee -a /etc/mkinitcpio.conf &>/dev/null

        sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<'TXT'
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_UsePageAttributeTable=1
options nvidia NVreg_EnablePCIeGen3=1
options nvidia NVreg_EnableResizableBar=1
options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x3; PowerMizerDefault=0x3; PowerMizerDefaultAC=0x3"
TXT

        sudo mkinitcpio -P &>/dev/null

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

info_print "Enabling Nvidia raytracing"
echo "#Nvidia variables:"
echo "VKD3D_CONFIG=dxr11,dxr" | sudo tee -a "/etc/environment" > /dev/null
echo "PROTON_ENABLE_NVAPI=1" | sudo tee -a "/etc/environment" > /dev/null
echo "PROTON_ENABLE_NGX_UPDATER=1" | sudo tee -a "/etc/environment" > /dev/null

echo -e "#NVIDIA" | sudo tee -a $HOME/.dotrepo/dotfiles/hypr/conf/autostart.conf &>/dev/null
echo -e "exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP" | sudo tee -a $HOME/.dotrepo/dotfiles/hypr/conf/autostart.conf &>/dev/null
echo -e "exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP" | sudo tee -a $HOME/.dotrepo/dotfiles/hypr/conf/autostart.conf &>/dev/null
echo -e "env = LIBVA_DRIVER_NAME,nvidia" | sudo tee -a $HOME/.dotrepo/dotfiles/hypr/conf/autostart.conf &>/dev/null
echo -e "env = XDG_SESSION_TYPE,wayland" | sudo tee -a $HOME/.dotrepo/dotfiles/hypr/conf/autostart.conf &>/dev/null
echo -e "env = GBM_BACKEND,nvidia-drm" | sudo tee -a $HOME/.dotrepo/dotfiles/hypr/conf/autostart.conf &>/dev/null
echo -e "env = __GLX_VENDOR_LIBRARY_NAME,nvidia" | sudo tee -a $HOME/.dotrepo/dotfiles/hypr/conf/autostart.conf &>/dev/null
echo -e "env = NVD_BACKEND,direct" | sudo tee -a $HOME/.dotrepo/dotfiles/hypr/conf/autostart.conf &>/dev/null

echo -e "cursor {" | sudo tee -a $HOME/.dotrepo/dotfiles/hypr/conf/autostart.conf &>/dev/null
echo -e "no_hardware_cursors = true" | sudo tee -a $HOME/.dotrepo/dotfiles/hypr/conf/autostart.conf &>/dev/null
echo -e "}" | sudo tee -a $HOME/.dotrepo/dotfiles/hypr/conf/autostart.conf &>/dev/null
    fi
}

intel_check () {
    if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq intel; then
        info_print "Intel GPU FOUND! Installing Intel-related packages."

        echo -e "" | sudo tee -a /etc/mkinitcpio.conf &>/dev/null
        echo -e "\nMODULES=(btrfs intel)" | sudo tee -a /etc/mkinitcpio.conf &>/dev/null
        sudo pacman -Syu mesa lib32-mesa vulkan-intel --noconfirm --needed
        info_print "Enabling Intel-raytracing support!"
        echo "#Intel Variables" | sudo tee -a "/etc/environment" > /dev/null
        echo "VKD3D_CONFIG=dxr11,dxr" | sudo tee -a "/etc/environment" > /dev/null
    fi
}

amd_check () {
    if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq amd; then
        info_print "AMD GPU FOUND! Installing AMD-related packages."

        echo -e "" | sudo tee -a /etc/mkinitcpio.conf &>/dev/null
        echo -e "\nMODULES=(btrfs amd)" | sudo tee -a /etc/mkinitcpio.conf &>/dev/null
        sudo pacman -Syu mesa lib32-mesa vulkan-radeon --noconfirm --needed
        info_print "Enabling AMD-raytracing support!"
        echo "#AMD Variables" | sudo tee -a "/etc/environment" > /dev/null
        echo "RADV_PERFTEST='rt'" | sudo tee -a "/etc/environment" > /dev/null
    fi
}


installing_packages () {
    info_print "Installing all the packages! (This may take some time)."

    # Fil for logging
    log_file="install_log.txt"

    # Liste over pakker fra offisielle repositorier
    pacman_packages=(
        "neovim"
        "ripgrep"
        "python-pynvim"
        "git"
        "github-cli"
        "wget"
        "rsync"
        "nfs-utils"
        "xorg-xwayland"
        "hyprland"
        "swaybg"
        "wl-clipboard"
        "waybar"
        "rofi-wayland"
        "egl-wayland"
        "alacritty"
        "dunst"
        "lxappearance"
        "thunar"
        "thunar-media-tags-plugin"
        "thunar-volman"
        "thunar-archive-plugin"
        "xdg-desktop-portal-hyprland"
        "qt5-wayland"
        "qt6-wayland"
        "hyprlock"
        "firefox"
        "ttf-font-awesome"
        "fastfetch"
        "ttf-fira-sans" 
        "ttf-fira-code"
        "adobe-source-code-pro-fonts"
        "ttf-firacode-nerd"
        "ttf-jetbrains-mono-nerd"
        "papirus-icon-theme"
        "fuse2"
        "htop"
        "gtk4"
        "libadwaita"
        "jq"
        "python-gobject"
        "nfs-utils"
        "pipewire"
        "pipewire-pulse"
        "wireplumber"
        "network-manager-sstp"
        "sstp-client"
        "firewalld"
        "p7zip"
        "unrar"
        "zip"
        "unzip"
        "udisks2"
        "udiskie"
        "pavucontrol"
        "network-manager-applet"
        "freecad"
        "blender"
        "gimp"
        "steam"
        "libreoffice-still"
        "mpv"
        #Gaming
        "piper"
        "vulkan-tools"
        "lutris"
        "gvfs"
        "mangohud"
        "gamemode"
        "discord"
        "gamescope"
        #DEV
        "cmake"
        "ninja"
        "qt5-base"
    )

    # Liste over pakker fra AUR
    aur_packages=(
        "brave-bin"
        "debtap"
        "spotify"
        "ventoy-bin"
        "opentabletdriver-git"
        "chitubox-free-bin"
        "pureref"
        "bibata-cursor-theme"
        "grimblast-git"
        #Gaming
    )

    # Oppdater systemet med pacman
    echo "Oppdaterer systemet med pacman..." | tee -a "$log_file" &>/dev/null
    if yes | sudo pacman -Syu --noconfirm --needed &>/dev/null; then
        echo "System oppdatert med pacman" | tee -a "$log_file" &>/dev/null
    else
        echo "Feil ved oppdatering av systemet med pacman" | tee -a "$log_file" &>/dev/null 
        exit 1 &>/dev/null
    fi

    # Installer pacman-pakker
    echo "Installerer pacman-pakker..." | tee -a "$log_file" &>/dev/null
    for package in "${pacman_packages[@]}"; do &>/dev/null
        attempt=1
        max_attempts=3
        success=false

        while [[ $attempt -le $max_attempts ]]; do
            if yes | sudo pacman -Syu --noconfirm --needed "$package" &>/dev/null; then
                echo "Installert: $package" | tee -a "$log_file" &>/dev/null
                success=true
                break
            else
                echo "Feil ved installasjon av $package, forsøk $attempt" | tee -a "$log_file" &>/dev/null
            fi
            ((attempt++))
        done

        if [[ $success == false ]]; then
            echo "Mislyktes å installere $package etter $max_attempts forsøk" | tee -a "$log_file" &>/dev/null
        fi
    done

    # Installer AUR-pakker
    echo "Installerer AUR-pakker..." | tee -a "$log_file" &>/dev/null
    for package in "${aur_packages[@]}"; do &>/dev/null
        attempt=1
        max_attempts=3
        success=false

        while [[ $attempt -le $max_attempts ]]; do &>/dev/null
            if yay -Syu --noconfirm "$package" &>/dev/null; then
                echo "Installert: $package" | tee -a "$log_file" &>/dev/null
                success=true
                break
            else
                echo "Feil ved installasjon av $package, forsøk $attempt" | tee -a "$log_file" &>/dev/null
            fi
            ((attempt++))
        done

        if [[ $success == false ]]; then &>/dev/null
            echo "Mislyktes å installere $package etter $max_attempts forsøk" | tee -a "$log_file" &>/dev/null
        fi
    done

    echo "Alle pakker er installert." | tee -a "$log_file"
}

setup_ly () {
    info_print "Installing Ly - display manager."
    sudo pacman -Syu ly --noconfirm &>/dev/null
    sudo systemctl enable ly.service &>/dev/null
}

setup_mousecursor () {
    input_print "Changing the cursor theme to: Bibata-Modern-Ice"
    sudo rm /usr/share/icons/default/index.theme &>/dev/null
    sudo touch /usr/share/icons/default/index.theme &>/dev/null
    sudo tee /usr/share/icons/default/index.theme > /dev/null <<'TXT'
[icon theme] 
Inherits=Bibata-Modern-Ice
TXT
}

start_services () {
    info_print "Starting services"
    sudo systemctl enable pipewire-pulse.service &>/dev/null
    sudo systemctl enable firewalld.service &>/dev/null
    systemctl --user enable opentabletdriver.service --now

    #NFS PORTS
    sudo firewall-cmd --zone=public --add-port4000=/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=4000/udp --permanent
    sudo firewall-cmd --zone=public --add-port4001=/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=4001/udp --permanent
    sudo firewall-cmd --zone=public --add-port4002=/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=4002/udp --permanent
    sudo firewall-cmd --reload

    #Aliases
    echo "alias ls='ls -la'" >> ~/.bashrc
    echo "alias ..='cd ..'" >> ~/.bashrc
    echo "alias gs='git status'" >> ~/.bashrc
    echo "alias yay='yay -Syu'" >> ~/.bashrc
    echo "alias upgrade='sudo ./usr/local/bin/update_and_clean_arch.sh'"
    echo "alias install='sudo pacman -Syu'" >> ~/.bashrc
    echo "alias update='sudo pacman -Syu'" >> ~/.bashrc
    source ~/.bashrc

    git config --global user.name  "aCeTotal"
    git config --global user.email "lars.oksendal@gmail.com"

for c in /etc/udev/rules.d/9{0,9}-opentabletdriver.rules; do
  if [ -f "${c}" ]; then
    echo "Deleting ${c}"
    sudo rm "${c}"
  fi
done

echo "Finding old kernel module blacklist rules..."
if [ -f /etc/modprobe.d/blacklist.conf ]; then
  echo "Deleting /etc/modprobe.d/blacklist.conf"
  sudo rm /etc/modprobe.d/blacklist.conf
fi

sudo modprobe uinput
sudo rmmod wacom hid_uclogic > /dev/null 2>&1

sudo udevadm control --reload-rules && sudo udevadm trigger
sudo mkinitcpio -P
}

check_if_laptop () {
    if acpi -b | grep -i "Battery" &>/dev/null; then
        info_print "This is a laptop. Laptop specific packages and settings will be installed. WARNING: This script is most likely adapted to one or more types of laptop, so you should look up your laptop in the Arch Wiki to manually do the recommended steps!"
        #MSI GS66 Stealth
        yay -Syu msi-perkeyrgb tlpui --noconfirm &>/dev/null
        yay -Syu isw --noconfirm &>/dev/null
        sudo pacman -Syu tlp hdparm iw --noconfirm --needed &>/dev/null
fi

            
# Opprett systemd-tjenestefilen direkte med sudo
sudo tee /etc/systemd/system/ec-config.service > /dev/null << EOF
[Unit]
Description=Configure EC register and run isw command
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/isw -s 0x72 0
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload &>/dev/null
sudo systemctl enable ec-config.service &>/dev/null
sudo systemctl start ec-config.service &>/dev/null
sudo systemctl enable tlp.service &>/dev/null
sudo systemctl start tlp.service &>/dev/null

return 0;
}

nfs_shares () {
  info_print "Adding NFS-shares!"
  sudo mkdir -p /mnt/nfs/bigdisk1 &>/dev/null
  sudo chmod go=rwx /mnt/nfs/bigdisk1 && sudo chown $USER: /mnt/nfs/bigdisk1 &>/dev/null
  echo -e "\n#NFS\n192.168.0.40:/export/bigdisk1        /mnt/nfs/bigdisk1       nfs     rw,defaults,noauto,nofail,users,x-systemd.automount,x-systemd.device-timeout=30,_netdev 0 0" | sudo tee -a /etc/fstab >/dev/null
  
  return 0;
}

neovim_install () {
    info_print "Configuring Neovim"
    git clone --depth 1 https://github.com/wbthomason/packer.nvim\
    ~/.local/share/nvim/site/pack/packer/start/packer.nvim

    #nvim ~/.config/nvim/lua/acetotal/packer.lua
    #:PackerSync

    return 0;
}

until enabling_multilib; do : ; done
until install_yay; do : ; done
until clone_dotfiles; do : ; done 
until usergroups; do : ; done
until nvidia_check; do : ; done
#until intel_check; do : ; done
#until amd_check; do : ; done
until installing_packages; do : ; done
until setup_ly; do : ; done
until setup_mousecursor; do : ; done
until start_services; do : ; done
#until check_if_laptop; do : ; done
until nfs_shares; do : ; done
until neovim_install; do : ; done

systemctl reboot

