#!/usr/bin/env -S bash -e

# Cleaning the TTY.
pacman -Sy &>/dev/null
pacman-key --init  &>/dev/null
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
}

enabling_multilib () {
    info_print "Enabling multilib."
    sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf &>/dev/null
    sudo pacman -Syu --noconfirm &>/dev/null
}

clone_dotfiles () {
    info_print "Cloning the dotfiles and adding symbolic links."

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
    info_print "Adding the $USER to the input group"
    sudo gpasswd -a $USER wheel input &>/dev/null
}

nvidia_check () {
    if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
        info_print "NVIDIA GPU FOUND! Installing nvidia-related packages!"
        sudo pacman -Syu --noconfirm --needed nvidia-dkms cuda libva-nvidia-driver nvidia-utils lib32-nvidia-utils &>/dev/null

        info_print "Creating modprobe config for your Nvidia card for max performance and wayland support" 
        sudo mkdir -p /etc/modprobe.d &>/dev/null
        sudo touch /etc/modprobe.d/nvidia.conf &>/dev/null
        echo -e "" | sudo tee -a /etc/mkinitcpio.conf
        echo -e "\nMODULES=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)" | sudo tee -a /etc/mkinitcpio.conf &>/dev/null

        sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<'TXT'
options nvidia-drm modeset=1
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

    else
        echo -e "" | sudo tee -a /etc/mkinitcpio.conf &>/dev/null
        echo -e "\nMODULES=(btrfs)" | sudo tee -a /etc/mkinitcpio.conf &>/dev/null
    fi
}

installing_packages () {
    info_print "Installing all the packages that we need."

    sudo pacman -Sy --noconfirm &>/dev/null

    # Fil for logging
    log_file="install_log.txt"

    # Liste over pakker fra offisielle repositorier
    pacman_packages=(
        "git"
        "wget"
        "rsync"
        "xorg-xwayland"
        "hyprland"
        "swaybg"
        "wl-clipboard"
        "waybar"
        "rofi-wayland"
        "alacritty"
        "dunst"
        "thunar"
        "xdg-desktop-portal-hyprland"
        "qt5-wayland"
        "qt6-wayland"
        "hyprlock"
        "firefox"
        "ttf-font-awesome"
        "vim"
        "fastfetch"
        "ttf-fira-sans" 
        "ttf-fira-code"
        "adobe-source-code-pro-fonts"
        "ttf-firacode-nerd"
        "ttf-jetbrains-mono-nerd"
        "papirus-icon-theme"
        "fuse2"
        "gtk4"
        "libadwaita"
        "jq"
        "python-gobject"
        "nfs-utils"
        "pipewire"
        "pipewire-jack"
        "pipewire-pulse"
        "wireplumber"
        "network-manager-sstp"
        "sstp-client"
        "firewalld"
        "p7zip"
        "unrar"
        "zip"
        "unzip"
        "pavucontrol"
        "network-manager-applet"
        "freecad"
        "blender"
        "gimp"
        "steam"
        "libreoffice-still"
        #Gaming
        "piper"
        "vulkan-tools"
        "lutris"
        "mangohud"
        "gamemode"
        "discord"
        "gamescope"
    )

    # Liste over pakker fra AUR
    aur_packages=(
        "brave-bin"
        "debtap"
        "spotify"
        "ventoy-bin"
        "bibata-cursor-theme"
        "grimblast-git"
        #Gaming
    )

    # Oppdater systemet med pacman
    echo "Oppdaterer systemet med pacman..." | tee -a "$log_file"
    if yes | sudo pacman -Syu --noconfirm --needed &>/dev/null; then
        echo "System oppdatert med pacman" | tee -a "$log_file"
    else
        echo "Feil ved oppdatering av systemet med pacman" | tee -a "$log_file"
        exit 1
    fi

    # Installer pacman-pakker
    echo "Installerer pacman-pakker..." | tee -a "$log_file"
    for package in "${pacman_packages[@]}"; do
        attempt=1
        max_attempts=3
        success=false

        while [[ $attempt -le $max_attempts ]]; do
            if yes | sudo pacman -Syu --noconfirm --needed "$package" &>/dev/null; then
                echo "Installert: $package" | tee -a "$log_file"
                success=true
                break
            else
                echo "Feil ved installasjon av $package, forsøk $attempt" | tee -a "$log_file"
            fi
            ((attempt++))
        done

        if [[ $success == false ]]; then
            echo "Mislyktes å installere $package etter $max_attempts forsøk" | tee -a "$log_file"
        fi
    done

    # Installer AUR-pakker
    echo "Installerer AUR-pakker..." | tee -a "$log_file"
    for package in "${aur_packages[@]}"; do
        attempt=1
        max_attempts=3
        success=false

        while [[ $attempt -le $max_attempts ]]; do
            if yay -Syu --noconfirm "$package" &>/dev/null; then
                echo "Installert: $package" | tee -a "$log_file"
                success=true
                break
            else
                echo "Feil ved installasjon av $package, forsøk $attempt" | tee -a "$log_file"
            fi
            ((attempt++))
        done

        if [[ $success == false ]]; then
            echo "Mislyktes å installere $package etter $max_attempts forsøk" | tee -a "$log_file"
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
}

check_if_laptop () {
    if acpi -b | grep -i "Battery" &>/dev/null; then
        info_print "This is a laptop. Laptop specific packages and settings will be installed. WARNING: This script is most likely adapted to one or more types of laptop, so you should look up your laptop in the Arch Wiki to manually do the recommended steps!"
        #MSI GS66 Stealth
        yes | yay -Syu msi-perkeyrgb tlpui --noconfirm
        yes | yay -Syu isw --noconfirm
        yes | sudo pacman -Syu tlp --noconfirm --needed
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

sudo systemctl daemon-reload
sudo systemctl enable ec-config.service
sudo systemctl start ec-config.service
sudo systemctl enable tlp.service
sudo systemctl start tlp.service

return 0;
else
    return 0;
}


until enabling_multilib; do : ; done
until install_yay; do : ; done
until clone_dotfiles; do : ; done 
until usergroups; do : ; done
until nvidia_check; do : ; done
until installing_packages; do : ; done
until setup_ly; do : ; done
until setup_mousecursor; do : ; done
until start_services; do : ; done
until check_if_laptop; do : ; done

systemctl reboot

