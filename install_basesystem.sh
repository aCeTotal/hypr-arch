#!/usr/bin/env -S bash -e

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

# Installing the chosen networking method to the system (function).
network_installer () {
    info_print "Installing and enabling NetworkManager."
    pacstrap /mnt networkmanager >/dev/null
    systemctl enable NetworkManager --root=/mnt &>/dev/null
}

# User enters a password for the LUKS Container (function).
lukspass_selector () {
    input_print "Please enter a password for the LUKS container (you're not going to see the password): "
    read -r -s password
    if [[ -z "$password" ]]; then
        echo
        error_print "You need to enter a password for the LUKS Container, please try again."
        return 1
    fi
    echo
    input_print "Please enter the password for the LUKS container again (you're not going to see the password): "
    read -r -s password2
    echo
    if [[ "$password" != "$password2" ]]; then
        error_print "Passwords don't match, please try again."
        return 1
    fi
    return 0
}

# Setting up a password for the user account (function).
userpass_selector () {
    input_print "Please enter name for a user account: "
    read -r username
    if [[ -z "$username" ]]; then
        return 0
    fi
    input_print "Please enter a password for $username (you're not going to see the password): "
    read -r -s userpass
    if [[ -z "$userpass" ]]; then
        echo
        error_print "You need to enter a password for $username, please try again."
        return 1
    fi
    echo
    input_print "Please enter the password again (you're not going to see it): " 
    read -r -s userpass2
    echo
    if [[ "$userpass" != "$userpass2" ]]; then
        echo
        error_print "Passwords don't match, please try again."
        return 1
    fi
    return 0
}

# Microcode detector (function).
microcode_detector () {
    CPU=$(grep vendor_id /proc/cpuinfo)
    if [[ "$CPU" == *"AuthenticAMD"* ]]; then
        info_print "An AMD CPU has been detected, the AMD microcode will be installed."
        microcode="amd-ucode"
    else
        info_print "An Intel CPU has been detected, the Intel microcode will be installed."
        microcode="intel-ucode"
    fi
}

# User enters a hostname (function).
hostname_selector () {
    input_print "Please enter the hostname Eg. OfficePC: "
    read -r hostname
    if [[ -z "$hostname" ]]; then
        error_print "You need to enter a hostname in order to continue. Eg. OfficePC"
        return 1
    fi
    return 0
}

# User chooses the locale (function).
locale_selector () {
    input_print "Please insert the locale you use (format: xx_XX. Enter empty to use en_US, or \"/\" to search locales): " locale
    read -r locale
    case "$locale" in
        '') locale="en_US.UTF-8"
            info_print "$locale will be the default locale."
            return 0;;
        '/') sed -E '/^# +|^#$/d;s/^#| *$//g;s/ .*/ (Charset:&)/' /etc/locale.gen | less -M
                clear
                return 1;;
        *)  if ! grep -q "^#\?$(sed 's/[].*[]/\\&/g' <<< "$locale") " /etc/locale.gen; then
                error_print "The specified locale doesn't exist or isn't supported."
                return 1
            fi
            return 0
    esac
}

# User chooses the console keyboard layout (function).
keyboard_selector () {
    input_print "Please insert the keyboard layout to use in console (Enter empty to use the Norwegian layout, type us for international english or \"/\" to look up for keyboard layouts): "
    read -r kblayout
    case "$kblayout" in
        '') kblayout="no-latin1"
            info_print "The standard Norwegian keyboard layout will be used."
            return 0;;
        '/') localectl list-keymaps
             clear
             return 1;;
        *) if ! localectl list-keymaps | grep -Fxq "$kblayout"; then
               error_print "The specified keymap doesn't exist."
               return 1
           fi
        info_print "Changing console layout to $kblayout."
        loadkeys "$kblayout"
        return 0
    esac
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
info_print "Welcome to the installation of HyprArch. A system that attempts to make the world of bleeding-edge software more stable and as user-friendly as possible with the 'Arch way' of doing things."
echo
# Choosing the target for the installation.
info_print "Available disks for the installation:"
lsblk -o NAME,SIZE,VENDOR,TYPE | awk '$4 == "disk" {print $1 " - " $2 ": (" $3 ")"}'
echo
PS3="Please select the number of the corresponding disk (e.g. 1): "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DISK="$ENTRY"
    info_print "Arch Linux will be installed on the following disk: $DISK"
    break
done

# Setting up keyboard layout.
until keyboard_selector; do : ; done

# Setting up LUKS password.
until lukspass_selector; do : ; done

# User choses the locale.
until locale_selector; do : ; done

# User choses the hostname.
until hostname_selector; do : ; done

# User sets up the user/root passwords.
until userpass_selector; do : ; done

# Warn user about deletion of old partition scheme.
input_print "WARNING! This will wipe the current partition table on $DISK once installation starts. Do you agree [y/N]?: "
read -r disk_response
if ! [[ "${disk_response,,}" =~ ^(yes|y)$ ]]; then
    error_print "Quitting."
    exit
fi
info_print "Wiping $DISK."
wipefs -af "$DISK" &>/dev/null
sgdisk -Zo "$DISK" &>/dev/null

# Creating a new partition scheme.
info_print "Creating the partitions on $DISK."
parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart CRYPTROOT 513MiB 100% \

ESP="/dev/disk/by-partlabel/ESP"
CRYPTROOT="/dev/disk/by-partlabel/CRYPTROOT"

# Informing the Kernel of the changes.
info_print "Informing the Kernel about the disk changes."
partprobe "$DISK"

# Formatting the ESP as FAT32.
info_print "Formatting the EFI Partition as FAT32."
mkfs.fat -F 32 "$ESP" &>/dev/null

# Creating a LUKS Container for the root partition.
info_print "Creating LUKS Container for the root partition."
echo -n "$password" | cryptsetup luksFormat "$CRYPTROOT" -d - &>/dev/null
echo -n "$password" | cryptsetup open "$CRYPTROOT" cryptroot -d - 
BTRFS="/dev/mapper/cryptroot"

# Formatting the LUKS Container as BTRFS.
info_print "Formatting the LUKS container as BTRFS."
mkfs.btrfs "$BTRFS" &>/dev/null
mount "$BTRFS" /mnt

# Creating BTRFS subvolumes.
info_print "Creating BTRFS subvolumes."
subvols=(snapshots var_pkgs var_log home root srv)
for subvol in '' "${subvols[@]}"; do
    btrfs su cr /mnt/@"$subvol" &>/dev/null
done

# Mounting the newly created subvolumes.
umount /mnt
info_print "Mounting the newly created subvolumes."
mountopts="ssd,noatime,compress-force=zstd:3,discard=async"
mount -o "$mountopts",subvol=@ "$BTRFS" /mnt
mkdir -p /mnt/{home,root,srv,.snapshots,var/{log,cache/pacman/pkg},boot}
for subvol in "${subvols[@]:2}"; do
    mount -o "$mountopts",subvol=@"$subvol" "$BTRFS" /mnt/"${subvol//_//}"
done
chmod 750 /mnt/root
mount -o "$mountopts",subvol=@snapshots "$BTRFS" /mnt/.snapshots
mount -o "$mountopts",subvol=@var_pkgs "$BTRFS" /mnt/var/cache/pacman/pkg
chattr +C /mnt/var/log
mount "$ESP" /mnt/boot/
#mount -o uid=0,gid=0,fmask=0077,dmask=0077 "$ESP" /mnt/boot/

# Checking the microcode to install.
microcode_detector

# Pacstrap (setting up a base sytem onto the new root).
info_print "Installing the base packages (it may take a while)."
pacstrap -K /mnt iwd base base-devel linux-zen "$microcode" linux-firmware linux-zen-headers git vim btrfs-progs xdg-user-dirs rsync efibootmgr snapper reflector snap-pac zram-generator sudo &>/dev/null

# Setting up the hostname.
echo "$hostname" > /mnt/etc/hostname

# Generating /etc/fstab.
info_print "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Configure selected locale and console keymap
sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
echo "LANG=$locale" > /mnt/etc/locale.conf
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

# Setting hosts file.
info_print "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Setting up the network.
network_installer

# Configuring /etc/mkinitcpio.conf.
info_print "Configuring /etc/mkinitcpio.conf."
cat > /mnt/etc/mkinitcpio.conf <<EOF
HOOKS=(systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems)
EOF

# Configuring the system.
info_print "Configuring the system (timezone, system clock, initramfs, Snapper, systemd-boot)."
arch-chroot /mnt /bin/bash -e <<EOF

    # Setting up timezone.
    ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null

    # Setting up clock.
    hwclock --systohc

    # Generating locales.
    locale-gen &>/dev/null

    # Generating a new initramfs.
    mkinitcpio -P &>/dev/null

    # Snapper configuration.
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots &>/dev/null
    mkdir /.snapshots
    mount -a &>/dev/null
    chmod 750 /.snapshots

    # Setting up systemd-boot.
    bootctl --path=/boot install &>/dev/null 
 

EOF

# Configuring systemd-boot loader entries.
info_print "Configuring systemd-boot loader entries."
mkdir -p /mnt/boot/loader/entries

# Hent PARTUUID for den krypterte partisjonen
PARTUUID=$(blkid -s PARTUUID -o value "$CRYPTROOT")

# Kontroller at PARTUUID ble funnet
if [ -z "$PARTUUID" ]; then
  echo "Kunne ikke finne PARTUUID for $CRYPTROOT"
  exit 1
fi

cat > /mnt/boot/loader/entries/hyprarch.conf <<EOF
title   HyprArch
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options cryptdevice=PARTUUID=$PARTUUID:cryptroot root=/dev/mapper/cryptroot rw
EOF

# Bekreft at filen er opprettet
if [ -f /mnt/boot/loader/entries/hyprarch.conf ]; then
  echo "Konfigurasjonsfilen er opprettet med PARTUUID=$PARTUUID"
else
  echo "Kunne ikke opprette konfigurasjonsfilen"
  exit 1
fi


# Creating systemd pacman hook
info_print "Creating systemd-boot pacman hook."
mkdir -p /mnt/etc/pacman.d/hooks
cat > /mnt/etc/pacman.d/hooks/95-systemd-boot.hook <<EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOF

# Setting user password.
if [[ -n "$username" ]]; then
    echo "%wheel ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/wheel
    info_print "Adding the user $username to the system with root privilege."
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"
    info_print "Setting user password for $username."
    echo "$username:$userpass" | arch-chroot /mnt chpasswd
fi

# Boot backup hook.
info_print "Configuring /boot backup when pacman transactions are made."
mkdir -p /mnt/etc/pacman.d/hooks
cat > /mnt/etc/pacman.d/hooks/50-bootbackup.hook <<EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up /boot...
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup
EOF

# ZRAM configuration.
info_print "Configuring ZRAM."
cat > /mnt/etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = lz4
EOF

# Pacman eye-candy features.
info_print "Enabling colours, animations, and parallel downloads for pacman."
sed -Ei 's/^#(Color)$/\1\nILoveCandy/;s/^#(ParallelDownloads).*/\1 = 10/' /mnt/etc/pacman.conf

# Enabling various services.
info_print "Enabling Reflector, automatic snapshots, BTRFS scrubbing and systemd-oomd."
services=(reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfs.path systemd-oomd)
for service in "${services[@]}"; do
    systemctl enable "$service" --root=/mnt &>/dev/null
done

info_print "Enabling multilib, installing AUR-helper Yay and adding the dotfiles."
arch-chroot /mnt su - $username

# Enable multilib for packages like Steam
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo pacman -Syu --noconfirm

# Installing the AUR-Helper YAY
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si --noconfirm
cd .. && rm -rf yay

# Cloning the dotfiles and wallpapers
mkdir /home/$username/.dotfiles
cd /home/$username/.dotfiles
git init
git remote add -f origin https://github.com/aCeTotal/hypr-arch.git
git config core.sparseCheckout true
echo "dotfiles/*" >> .git/info/sparse-checkout
git pull origin master
sudo mkdir -p /usr/share/wallpapers
cp /home/$username/.dotfiles/wallpapers/* /usr/share/wallpapers
rm -rf /home/$username/.dotfiles/wallpapers 
chown -R $username:$username /home/$username/.dotfiles

# Adding the current user to groups
gpasswd -a $username wheel input  >/dev/null

info_print "Installing the rest of the packages."
arch-chroot /mnt su - $username

sudo pacman -Syu --noconfirm sddm nfs-utils qt5-wayland qt5ct wofi xdg-desktop-portal-hyprland qt6-wayland qt6ct qt5-svg qt5-quickcontrols2 qt5-graphicaleffects gtk3 polkit-gnome pipewire pipewire-pulse pipewire-jack jq network-manager-sstp sstp-client 
sudo pacman -Syu --noconfirm swaybg github-cli wl-clipboard cliphist timeshift fail2ban swaybg ttf-jetbrains-mono-nerd papirus-icon-theme thunar
sudo pacman -Syu --noconfirm wireplumber grim slurp pkgfile swappy linux-headers firewalld rmlint rebuild-detector p7zip unrar rar zip unzip
sudo pacman -Syu --noconfirm network-manager-applet pavucontrol freecad steam
sudo pacman -Syu --noconfirm grim slurp swappy hyprland-git
yay -Syu --noconfirm --needed alacritty rider blender gimp libreoffice-still dropbox spotify ventoy-bin
yay -Syu --noconfirm stm32cubemx hyprland-git
yay -Syu --noconfirm teams debtap
yay -Syu --noconfirm waybar-git downgrade bibata-cursor-theme

sudo pacman -Syu piper vulkan-tools wine-staging gamescope discord gamemode mangohud lutris steam
yay -Syu --noconfirm xone-dkms

# Check if NVIDIA GPU is found
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
info_print "NVIDIA GPU FOUND! Installing nvidia-related packages!"  
yay -Syu --noconfirm --needed nvidia-dkms libva libva-nvidia-driver nvidia-utils lib32-nvidia-utils
sudo pacman -Syu steam

info_print "Creating modprobe config for your Nvidia card for max performance and wayland support" 
   sudo mkdir -p /etc/modprobe.d >/dev/null
   sudo touch /etc/modprobe.d/nvidia.conf >/dev/null
   echo -e "\nMODULES=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)" | sudo tee -a /etc/mkinitcpio.conf >/dev/null
   
   sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<'TXT'
   options nvidia_drm modeset=1
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


else
   echo -e "\nMODULES=(btrfs)" | sudo tee -a /etc/mkinitcpio.conf >/dev/null
fi

# Citrix Workspace.
input_print "Do you want to install the Citrix Workspace client? [y/N]?: "
read -r citrix_response
if [[ "${citrix_response,,}" =~ ^(yes|y)$ ]]; then
info_print "Installing the Citrix Workspace client"
yay -Syu icaclient --noconfirm >/dev/null
mkdir -p ~/.ICACLIENT/cache/ >/dev/null

sed -i 's/TWIMode=*/TWIMode=0/g' /opt/Citrix/ICAClient/config/All_Regions.ini 
sed -i 's/DesiredColor=*/DesiredColor=8/g' /opt/Citrix/ICAClient/config/All_Regions.ini
sed -i 's/DesiredHRES=*/DesiredHRES=1024/g' /opt/Citrix/ICAClient/config/All_Regions.ini
sed -i 's/DesiredVRES=*/DesiredVRES=768/g' /opt/Citrix/ICAClient/config/All_Regions.ini  
sed -i 's/UseFullScreen=*/UseFullScreen=false/g' /opt/Citrix/ICAClient/config/All_Regions.ini  
sed -i 's/TWIFullScreenMode=*/TWIFullScreenMode=false/g' /opt/Citrix/ICAClient/config/All_Regions.ini  
sed -i 's/NoWindowManager=*/NoWindowManager=false/g' /opt/Citrix/ICAClient/config/All_Regions.ini

mkdir -p /usr/share/applications/
touch /usr/share/applications/wfica.desktop
tee /usr/share/applications/wfica.desktop > <<'TXT'
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
mkdir -p /usr/share/wayland-sessions >/dev/null
echo -e "[Desktop Entry]\nName=Hyprland\nComment=An intelligent dynamic tiling Wayland compositor\nExec=Hyprland\nType=Application" | sudo tee -a /usr/share/wayland-sessions/hyprland.conf

info_print "Adding nfs-shares"
sudo mkdir -p /mnt/nfs/bigdisk1
  sudo chmod go=rwx /mnt/nfs/bigdisk1/ && sudo chown $username: /mnt/nfs/bigdisk1
  echo -e "\n#NFS\n192.168.0.40:/bigdisk1        /mnt/nfs/bigdisk1       nfs     rw,defaults,noauto,nofail,users,x-systemd.automount,x-systemd.device-timeout=30,_netdev 0 0" | sudo tee -a /etc/fstab


# Cursor Theme
input_print "Changing the cursor theme to: Bibata-Modern-Ice"
sudo rm /usr/share/icons/default/index.theme
sudo touch /usr/share/icons/default/index.theme
sudo tee /usr/share/icons/default/index.theme > /dev/null <<'TXT'
[icon theme] 
Inherits=Bibata-Modern-Ice
TXT

# Adding some aliases
input_print "Adding some aliases"
rm $HOME/.bashrc && touch $HOME/.bashrc
$HOME/.bashrc > /dev/null <<'TXT'
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


echo
echo
info_print "The installation is complete! Please remove usb and type reboot!"
exit
