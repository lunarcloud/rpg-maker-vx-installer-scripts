# RPG Maker XP / VX / VX Ace Installer Creation Scripts
Create installers for RPG Maker XP or VX (Ace) games for Windows, Mac, and Linux (Debian / Ubuntu).

## Engine
On Linux and Mac, [mkxp](https://github.com/Ancurio/mkxp) is used as the native game executable.
Please refer to their documentation for compatibility issues with running your game. For example, they cannot support games that use third-party dlls for obvious reasons.

## Downloading
Please use git clone --recurse-submodules https://github.com/lunarcloud/rpg-maker-vx-installer-scripts.git

## Prerequisites
This was made to run on Linux.
If you don't have Linux running yet, I suggest installing [VirtualBox](https://www.virtualbox.org) and installing the latest LTS version of [Ubuntu](https://www.ubuntu.com/download/desktop) on it.

Ubuntu / Debian users can use this to set up:
`sudo apt install curl icnsutils nsis wine`

## Instructions
  1. Create a folder for your installer project
  2. Drop your RPG Maker VX game into this folder
  3. Create the game.png
  4. Create your gameinfo.conf
  5. (Optional) create the company.png
  6. (Optional) create a license.txt
  7. Run gui.sh
