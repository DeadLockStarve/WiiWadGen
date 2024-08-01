# WiiWadGen
MacOS and Linux alternative to WiiWSC, re-edited from [MyWiiShortcut](https://github.com/DouglasMartins1999/MyWiiShortcut)

WiiWadGen is a script to generate game shortcuts/forwarders for Wii games using tools available in *nix system - loading them with WiiFlow/USB Loader GX.

This tool is available for Intel and Apple Silicon Macs running MacOS 11.x or later, and Linux systems using Intel (x64) or ARM64 processors - binaries was build in Ubuntu 16.04 LTS and should works on most of modern distros.

## How it works?
This script is only viable because of four tools: 

 - [WiiGSC](https://www.gamebrew.org/wiki/WiiGSC)
 - [Wiimms' ISO Tools (WIT)](https://wit.wiimm.de)
 - [WadTools by BFGR](https://github.com/libertyernie/wad-tools)
 - [Unix xxd](https://linux.die.net/man/1/xxd)

In order to function, this script needs `wit` from Wiimm's tools, `wadpacker` and `wadunpacker` from WadTools installed in `$PATH`. Check your distro's repos for availability, otherwise compile them by yourself.

Base wad files have been extracted by **MyWiiShortcut** author from **WiiGSC**, this script uses `wadunpacker` to unpack them, `wit` to extract banners and data from a wbfs, `xxd` to override the loader's configs and then repacks and signs the .wad installer file using `wadpacker`.

## Installation

You can install this script with this procedure:

    git clone https://github.com/DeadLockStarve/WiiWadGen
    cd WiiWadGen
    sudo cp wiiwadgen.sh /usr/local/bin/
    sudo chown root:root /usr/local/bin/wiiwadgen.sh
    sudo chmod 0755 /usr/local/bin/wiiwadgen.sh

Then place the utils directory in a directory of choice and pass them to the script either by doing

    WAD_UTILS_DIR="/yourdir" wiiwadgen.sh

or by setting `WAD_UTILS_DIR` in `~/.bashrc`

> You will NEED a copy of wii `common-key.bin` to make wad tools work, after you obtained it place it in `$WAD_UTILS_DIR/keys/common-key.bin`

## How to use

Just cd in your preferred directory then do

    wiiwadgen.sh forwarder -r 'path/to/your/file.wbfs' -l WiiFlow

A wad file ready for installation will be generated in `dest/` folder in your current directory. Other options are explained in the help message by doing `wiiwadgen.sh forwarder -h`

**WARNING!! Like on WiiGSC, only install .wads if you have a brick-safe Wii (with BootMii / Priiloader installed) - is know that forwarders for some games could brick your Wii, so is HEAVILY RECOMMENDED to make an backup of your NAND before any install.**

## Advanced usage
By using `wadgen.sh gen` mode you can customize more things, for example:

 - Use a banner of one game to load any other
 - Use your own custom banners
 - Use any loader of your choice - not tested
 - Maybe, create shortcuts for GC games - also, not tested
