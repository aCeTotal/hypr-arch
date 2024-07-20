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
info_print "Welcome to the first part of installing Hypr-Arch!"

# Setting up keyboard layout.
until keyboard_selector; do : ; done

# Choosing the target for the installation.
info_print "Available disks for the installation:"
lsblk
PS3="Please select the number of the corresponding disk (e.g. 1): "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DISK="$ENTRY"
    info_print "Arch Linux will be installed on the following disk: $DISK"
    break
done

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
info_print "Creating the LUKS Container for the root partition."
echo -n "$password" | cryptsetup luksFormat "$CRYPTROOT" -d - &>/dev/null

# Opening the newly created LUKS Container.
info_print "Opening the newly created LUKS Container."
echo -n "$password" | cryptsetup open "$CRYPTROOT" cryptroot -d - &>/dev/null

# Formatting the LUKS Container as BTRFS.
info_print "Formatting the LUKS container as BTRFS."
mkfs.btrfs /dev/mapper/cryptroot &>/dev/null

# Mounting the newly created BTRFS container.
info_print "Mounting the newly created BTRFS container."
mount /dev/mapper/cryptroot /mnt

# Creating BTRFS subvolumes.
info_print "Creating BTRFS subvolumes."
btrfs su cr /mnt/@ &>/dev/null
btrfs su cr /mnt/@home &>/dev/null
btrfs su cr /mnt/@srv &>/dev/null
btrfs su cr /mnt/@snapshots &>/dev/null
btrfs su cr /mnt/@var_log &>/dev/null
btrfs su cr /mnt/@pkg &>/dev/null

# Unmounting the BTRFS container.
info_print "Unmounting the BTRFS container."
umount /mnt

# Mounting the newly created subvolumes.
info_print "Mounting the BTRFS subvolumes."
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@ /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,srv,.snapshots,/var/log,/var/cache/pacman/pkg}
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@srv /dev/mapper/cryptroot /mnt/srv
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@var_log /dev/mapper/cryptroot /mnt/var/log
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@pkg /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg

# Mounting the boot partition.
info_print "Mounting the boot partition."
mkdir -p /mnt/boot
mount "$ESP" /mnt/boot

# Base + base-devel + kernel + firmware.
info_print "Installing the base system (it may take a while)."
microcode_detector
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware btrfs-progs snapper vi vim "$microcode" sudo >/dev/null

# Generating an fstab.
info_print "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Setting up the system.
info_print "Setting up the system."
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime &>/dev/null
arch-chroot /mnt hwclock --systohc &>/dev/null
echo "$locale UTF-8" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen &>/dev/null
echo "LANG=$locale" > /mnt/etc/locale.conf
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf
echo "$hostname" > /mnt/etc/hostname

# Configuring the hosts file.
info_print "Configuring /etc/hosts."
cat <<EOF > /mnt/etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain $hostname
EOF

# Setting up Snapper configuration for root.
info_print "Setting up Snapper configuration for the root partition."
arch-chroot /mnt snapper --no-dbus -c root create-config /

# Creating a new initial ramdisk.
info_print "Creating a new initramfs."
sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P &>/dev/null

# Setting the root password.
info_print "Setting the root password."
echo -e "$password\n$password" | arch-chroot /mnt passwd &>/dev/null

# Setting the user password if username isn't empty.
if [[ -n "$username" ]]; then
    info_print "Creating $username with root privilege."
    arch-chroot /mnt useradd -m "$username" &>/dev/null
    echo -e "$userpass\n$userpass" | arch-chroot /mnt passwd "$username" &>/dev/null
    echo "$username ALL=(ALL) ALL" >> /mnt/etc/sudoers.d/"$username"
fi

# Setting up the Network.
network_installer

# Installing systemd-boot.
info_print "Installing systemd-boot."
arch-chroot /mnt bootctl install &>/dev/null

# Configuring systemd-boot.
info_print "Configuring systemd-boot."
UUID=$(blkid -s UUID -o value "$CRYPTROOT")
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux-zen
initrd /$microcode.img
initrd /initramfs-linux-zen.img
options cryptdevice=UUID=$UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw
EOF

cat <<EOF > /mnt/boot/loader/loader.conf
default arch
timeout 5
console-mode max
editor no
EOF

# Enabling periodic TRIM for SSDs.
info_print "Enabling periodic TRIM for SSDs."
arch-chroot /mnt systemctl enable fstrim.timer &>/dev/null

# Enabling Snapper timeline and cleanup timers.
info_print "Enabling Snapper timeline and cleanup timers."
arch-chroot /mnt systemctl enable snapper-timeline.timer &>/dev/null
arch-chroot /mnt systemctl enable snapper-cleanup.timer &>/dev/null

# Prompt user for post-installation script.
input_print "Which post-installation script would you like to run? (1 = desktop, 2 = htpc): "
read -r script_choice
case "$script_choice" in
    1) info_print "Desktop script will be executed after reboot."
       echo "bash <(curl -sL bit.ly/install_hyprarch)" > /mnt/root/post_install.sh;;
    2) info_print "HTPC script will be executed after reboot."
       echo "bash <(curl -sL bit.ly/install_hyprhtpc)" > /mnt/root/post_install.sh;;
    *) error_print "Invalid choice. No post-installation script will be executed.";;
esac

info_print "Making post_install.sh executable."
chmod +x /mnt/root/post_install.sh

# Finalizing the installation.
info_print "The first part of installation is done. Please reboot and run /root/post_install.sh after reboot to complete the setup."

# Unmounting all partitions.
info_print "Unmounting all partitions."
umount -R /mnt

# Informing the user that the installation is done.
info_print "The installation is complete. You can reboot now."
