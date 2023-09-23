How to install hypr-arch (Arch Linux with Hyprland): WARNING: WORK-IN-PROGRESS!

1. Download the latest image of Arch Linux and place it on a memory stick with Ventoy or similar.

2. Make sure your BIOS is set to only use UEFI and Secure Boot disabled.

3. Boot up Arch Linux -> If you don't normally use an English keyboard, change the keyboard layout with loadkeys (eg loadkeys no-latin1 for Norwegian) -> make sure you have internet (ping google.com).

4. bash <(curl -sL bit.ly/install_basesystem)

5. Reboot the system -> Log in with your user and password.

6. bash <(curl -sL bit.ly/install_hyprarch)

7. You can start using your system. (You may need to hit the user icon in the middle of the SDDM/Login screen to select your user.) Make your own changes in hyprland config: vim .config/hypr/hyprland.conf, especially screen resolution, framerate and bindings. Until that happens:

SUPER + Enter = Terminal, 
SUPER + P = App launcher, 
SUPER + Q = Kill Window,
SUPER + BACKSPACE = Browser, 
SUPER + E = File Browser, 
SUPER + S = SCREENSHOT, 
SUPER + [1-9] = Change workspace

================

8. In steam, make sure you select Proton Experimental - Bleeding Edge, for the latest version of Proton and DXVK. Very important. (Right click on Proton Experimental -> betas -> Select Bleeding Edge.)

9. Update the system + packages with the command 'update' and install new packages with the command 'install <package>'. (Just a tip and an attempt to make Arch Linux a bit more stable for people who don't update every week.).

10. Good luck! :)
