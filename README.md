# RPG Maker XP / VX / VX Ace Installer Creation Scripts
Create installers for RPG Maker XP or VX (Ace) games for Windows, Mac, and Linux (Debian / Ubuntu).
On Linux and Mac, [mkxp](https://github.com/Ancurio/mkxp) is used to create native applications. On Linux, launching with wine is an option when wine is installed.

## Environment
This was made to run on Linux.
You will need [Cygwin](https://www.cygwin.com/) or [WSL](https://msdn.microsoft.com/commandline/wsl/about).
It may not work on macOS. Patches to script-dialog and/or this to make it work would be welcome.

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
