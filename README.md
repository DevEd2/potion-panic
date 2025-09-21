# Moved
This repository has moved to [Codeberg](https://codeberg.org/DevEd/potion-panic). The source code for the GBCompo25 demo will remain here, but any future development will happen at Codeberg.

# Potion Panic
A single-screen platformer for Game Boy Color, created for GBCompo 2025. After accidentally releasing a demon due to a magic trick gone horribly wrong, Natalie the magician must defeat the demon and undo the damage before it's too late!

## Build requirements
- [RGBDS](https://rgbds.gbdev.io)
- [Python 3](https://python.org)
- [SuperFamiconv](https://github.com/optiroc/superfamiconv)

## Building the ROM
NOTE: On Windows, [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) is required. I am currently unable to verify whether or not the repo can be built on macOS.

1. Clone the repo: `$ git clone --recursive https://github.com/DevEd2/potion-panic`
2. Run `build.sh`. If you get a "permission denied" error, run `chmod -x build.sh` and try again.


