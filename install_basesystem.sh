
#!/usr/bin/env bash

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
    echo -ne "${BOLD}${BYELLOW}[ ${GREEN}•${BYELLOW} ] $1${RESET}"
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

# Ask user which post-install script to run (function).
postinstall_selector () {
    echo
    input_print "Which configuration do you want to install? (1 = desktop, 2 = htpc): "
    read -r postinstall_choice
    if [[ "$postinstall_choice" == "1" ]]; then
        postinstall_script="bash <(curl -sL bit.ly/install_hyprarch)"
    elif [[ "$postinstall_choice" == "2" ]]; then
        postinstall_script="bash <(curl -sL bit.ly/install_hyprhtpc)"
    else
        error_print "Invalid choice, please enter 1 or 2."
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

# List available disks and let the user select one.
disk_selector () {
    echo
    info_print "Listing available disks:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v 'loop'
    echo
    input_print "Enter the disk to install the system on (e.g., /dev/sda): "
    read -r DISK
    if [[ ! -b "$DISK" ]]; then
        error_print "$DISK is not a valid disk."
        return 1
    fi
    return 0
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
info_print "Welcome to the first part of installing Hypr-Arch!"

# Selecting and checking disk.
while ! disk_selector; do :; done

# Selecting and checking password.
while ! lukspass_selector; do :; done

# Selecting and checking hostname.
while ! hostname_selector; do :; done

# Selecting and checking locale.
while ! locale_selector; do :; done

# Selecting and checking keyboard layout.
while ! keyboard_selector; do :; done

# Detecting microcode.
microcode_detector

# Choosing post-install script.
while ! postinstall_selector; do :; done

# Erase old partition table.
info_print "Cleaning partition table on $DISK."
sgdisk -Z "$DISK" >/dev/null

# Creating the partitions.
info_print "Creating a new partition scheme on $DISK."
sgdisk -a 2048 -o "$DISK" >/dev/null
sgdisk -n 1::+550M --typecode=1:ef00 --change-name=1:EFI "$DISK" >/dev/null
sgdisk -n 2::-0 --typecode=2:8309 --change-name=2:cryptroot "$DISK" >/dev/null
info_print "Partitions have been created on $DISK."
EFI_PART="${DISK}1"
CRYPT_PART="${DISK}2"

# Formatting and setting up partitions.
info_print "Formatting the EFI partition."
mkfs.vfat -F32 "$EFI_PART" &>/dev/null

# Setting up the LUKS container.
info_print "Creating LUKS container on $CRYPT_PART."
echo -n "$password" | cryptsetup -q luksFormat "$CRYPT_PART" -d - &>/dev/null
info_print "Opening the LUKS container."
echo -n "$password" | cryptsetup open "$CRYPT_PART" cryptroot -d - &>/dev/null

# Creating BTRFS filesystem on cryptroot.
info_print "Creating BTRFS filesystem on /dev/mapper/cryptroot."
mkfs.btrfs --quiet /dev/mapper/cryptroot &>/dev/null
info_print "BTRFS filesystem has been created."

# Mounting the new filesystem.
info_print "Mounting the BTRFS filesystem."
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@ &>/dev/null
btrfs subvolume create /mnt/@home &>/dev/null
btrfs subvolume create /mnt/@root &>/dev/null
btrfs subvolume create /mnt/@srv &>/dev/null
btrfs subvolume create /mnt/@cache &>/dev/null
btrfs subvolume create /mnt/@log &>/dev/null
btrfs subvolume create /mnt/@tmp &>/dev/null
umount /mnt

# Mounting subvolumes.
info_print "Mounting the BTRFS subvolumes."
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@ /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,root,srv,var/cache,var/log,var/tmp}
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@root /dev/mapper/cryptroot /mnt/root
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@srv /dev/mapper/cryptroot /mnt/srv
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@cache /dev/mapper/cryptroot /mnt/var/cache
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@log /dev/mapper/cryptroot /mnt/var/log
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@tmp /dev/mapper/cryptroot /mnt/var/tmp

# Mounting the EFI partition.
info_print "Mounting the EFI partition."
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

# Installing the base system and required packages.
info_print "Installing the base system (this may take a while)."
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs "$microcode" --noconfirm --quiet

# Generating the fstab.
info_print "Generating the fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Setting up the hostname.
echo "$hostname" > /mnt/etc/hostname

# Setting up the locale.
sed -i "s/#$locale/$locale/" /mnt/etc/locale.gen
echo "LANG=$locale" > /mnt/etc/locale.conf

# Setting up the console keyboard layout.
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

# Configuring the initramfs.
info_print "Configuring the initramfs."
arch-chroot /mnt mkinitcpio -P

# Setting the root password.
echo "root:$userpass" | arch-chroot /mnt chpasswd

# Creating the user and setting the password.
if [[ -n "$username" ]]; then
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"
    echo "$username:$userpass" | arch-chroot /mnt chpasswd
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
fi

# Installing the bootloader (systemd-boot).
info_print "Installing systemd-boot."
arch-chroot /mnt bootctl install

# Creating loader configuration.
cat <<EOF > /mnt/boot/loader/loader.conf
default arch
timeout 5
editor 0
EOF

# Creating boot entry for systemd-boot.
UUID=$(blkid -s UUID -o value "$CRYPT_PART")
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options cryptdevice=UUID=$UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw
EOF

# Installing the chosen networking solution.
network_installer

# Finalizing the installation.
info_print "Finalizing the installation."

# Running the chosen post-install script.
arch-chroot /mnt $postinstall_script

info_print "Installation complete! You can now reboot into your new system."
