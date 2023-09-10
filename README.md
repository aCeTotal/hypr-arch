These scripts give you my system with Arch Linux and Hyperland. Neat and fast system with maximum gaming performance with Nvidia (Other GPU's does work aswell). The scripts are still work-in-progress, but exactly the same as I use. It works and as of now has given me the best gaming performance ever on Linux.

1. Download the latest image of Arch Linux and place it on a memory stick with Ventoy or similar.

2. Make sure your BIOS is set to only use UEFI and Secure Boot disabled.

3. Boot up Arch Linux -> If you don't normally use an English keyboard, change the keyboard layout with loadkeys (eg loadkeys no-latin1 for Norwegian) -> make sure you have internet (ping google.com).

4. bash <(curl -sL bit.ly/install_basesystem)

5. Reboot the system -> Log in with your user and password.

6. git clone https://github.com/aCeTotal/hypr-arch.git

7. cd hypr-arch -> sudo chmod +x install_hyprland.sh

8. Read through the content of install_hyprland.sh and remove packages that you don't need. May break default bindings, but you should always remove packages that you don't need!

9. ./install_hyprland.sh (IMPORTANT! Select the correct VULKAN-DRIVER for your GPU!)

10. You can start using your system. (You may need to hit the user icon in the middle of the SDDM/Login screen to select your user.) Make your own changes in hyprland config: vim .config/hypr/hyprland.conf, especially screen resolution, framerate and bindings. Until that happens:

SUPER + Enter = Terminal, 
SUPER + P = App launcher, 
SUPER + Q = Kill Window,
SUPER + BACKSPACE = Browser, 
SUPER + E = File Browser, 
SUPER + S = SCREENSHOT, 
Change workspace with SUPER + [1-9]

================

10. In steam, make sure you select Proton Experimental - Bleeding Edge, for the latest version of Proton and DXVK. Very important. (Right click on Proton Experimental -> betas -> Select Bleeding Edge.)

11. Update the system + packages with the command 'update' and install new packages with the command 'install <package>'. (Just a tip and an attempt to make Arch Linux a bit more stable for people who don't update every week.).

12. Good luck! :)
