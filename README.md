# RPG Maker XP / VX / VX Ace Installer Creation Scripts
Create installers for RPG Maker XP or VX (Ace) games for Windows, Mac, and Linux (Debian / Ubuntu).

## Engine
On Linux and Mac, [mkxp](https://github.com/Ancurio/mkxp) is used as the native game executable.
Please refer to their documentation for compatibility issues with running your game.

## Downloading
Please use git clone --recurse-submodules https://github.com/lunarcloud/rpg-maker-vx-installer-scripts.git

## Prerequisites

### Software
This was made to run on Linux.
If you don't have Linux running yet, I suggest installing [VirtualBox](https://www.virtualbox.org) and installing the latest LTS version of [Ubuntu](https://www.ubuntu.com/download/desktop) on it.

Ubuntu / Debian users can use this to set up:
`sudo apt install curl icnsutils nsis wine flatpak-builder`

### Save Data
You cannot, as is default, have save files where the program files live. Windows 7 or newer, Linux, and macOS do not allow this for installed applications, and expect you to save data to the current user's data folder.

See DataManager.example.rb for an example of script changes to do this.

### No Extra DLLs
Your game cannot be using any special addons that require DLLs. MXKP is used to replace the standard RPG Maker software (and it's DLLs) and it does not use any sort of emulation that might enable your extra DLLs to work.

## Instructions
  1. Create a folder for your installer project
  2. Make sure your game saves in a user folder
  3. Drop your RPG Maker VX game into this folder
  4. Create the game.png
  5. Create your gameinfo.conf
  6. (Optional) create the company.png
  7. (Optional) create a license.txt
  8. Run gui.sh
