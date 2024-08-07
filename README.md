What do you get?

- My personal Arch setup with Hyprland. Either fork it or install it and then delete the packages you don't need later.
- Drawing/Graphics tablets works out-of-the-box.
- Top performance with Nvidia.
- No GRUB, only UEFI Systemd-boot.
- LUKS2 encryption of the whole root-partition. Your data will always be safe.
- Zen-kernel = Stable, Performance Optimizations, Improved Responsiveness, Better Interactivity, Low-Latency Tweaks, Enhanced Scheduler and Better Gaming Performance.
- Compressed Zram = Improved Memory Utilization, A lot faster Performance Compared to Disk Swap, Reduced I/O Load, Lower Latency, Energy Efficiency, Enhanced System Stability, Minimal Overhead
- systemd-oomd = improve the stability and responsiveness of the system by proactively identifying and handling processes that consume excessive amounts of memory.
- BTRFS filesystem.
- BTRFS snapshots = Does automatically backup your volumes based on a weekly schedule and every time you install/updates a package.

How to install it?

1. Download the latest image of Arch Linux and place it on a usb-stick with Ventoy or similar.

2. Make sure your BIOS is set to only use UEFI and Secure Boot disabled.

3. Boot up Arch Linux -> If you don't normally use an English keyboard, change the keyboard layout with loadkeys (eg loadkeys no-latin1 for Norwegian) -> make sure you have internet (ping google.com).

4. bash <(curl -sL bit.ly/install_basesystem)

5. Reboot the system -> Log in with your user and password.

6. bash <(curl -sL bit.ly/install_hyprarch)

7. You can start using your system.

- SUPER + Enter = Terminal 
- SUPER + P = App launcher 
- SUPER + Q = Kill Window
- SUPER + BACKSPACE = Browser 
- SUPER + E = File Browser 
- PrintScreen = SCREENSHOT 
- SUPER + [1-9] = Change workspace

8. In steam, make sure you select Proton Experimental - Bleeding Edge, for the latest version of Proton and DXVK. (Right click on Proton Experimental -> betas -> Select Bleeding Edge.)
   
9. Good luck! :)
