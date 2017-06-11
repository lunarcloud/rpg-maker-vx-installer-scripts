# RPG Maker XP / VX / VX Ace Installer Creation Scripts
Create installers for RPG Maker XP or VX (Ace) games for Windows, Mac, and Linux (Debian / Ubuntu).
On Linux and Mac, [mkxp](https://github.com/Ancurio/mkxp) is used to create native applications. On Linux, launching with wine is an option when wine is installed.

## Prerequisites
This was made to run on Linux.
If you don't have Linux running yet, I suggest installing [VirtualBox](https://www.virtualbox.org) and installing the latest LTS version of [Ubuntu](https://www.ubuntu.com/download/desktop) on it.

Then run the following command in the terminal which will install an icon converter tool for the macOS builder and the Windows installer creation tool NSIS:
`sudo apt install icnsutils nsis`

## Instructions
  1. Create a folder for your installer project
  2. Drop your RPG Maker VX game into this folder
  3. Create the game.png
  4. Create your gameinfo.conf
  5. (Optional) create the company.png
  6. (Optional) create a license.txt
  7. Run gui.sh or individually run build-* scripts
  8. ???
  9. Profit!
