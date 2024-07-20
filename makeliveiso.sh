#!/usr/bin/env bash
set -e

# Ensure archiso is installed
sudo pacman -S --needed archiso

# Create a working directory
WORKDIR=~/archlive
mkdir -p $WORKDIR

# Copy the releng profile (default Arch ISO profile)
cp -r /usr/share/archiso/configs/releng $WORKDIR

# Enter the working directory
cd $WORKDIR/releng

# Add custom packages
echo "git" >> packages.x86_64

# Add custom commands to airootfs
cat << 'EOF' >> airootfs/root/customize_airootfs.sh
#!/bin/bash
set -e

# Clone the repository
git clone git@github.com:aCeTotal/hypr-arch.git /root/hypr-arch

# Run the install_basesystem.sh script
bash /root/hypr-arch/install_basesystem.sh
EOF

# Make the script executable
chmod +x airootfs/root/customize_airootfs.sh

# Build the ISO
sudo mkarchiso -v .

# Move the ISO to a specific directory if needed
mkdir -p ~/custom_archiso
mv out/*.iso ~/custom_archiso/

echo "Custom Arch Linux ISO has been created and is located in ~/custom_archiso/"

