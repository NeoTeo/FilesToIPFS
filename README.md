# FilesToIPFS

A macOS native app that uses the swift-ipfs-api library and a local IPFS node to add files to the IPFS network.

## Requirements

An active IPFS node.

## Install

The app is runnable anywhere but to make it really useful I use it as a Finder service. To do that you need to:
1. Open Automator and create a new Service.
2. Select from the drop down menus "files or folders" in "Finder".
3. Drag in a "Run Shell Script" action.
4. type `open /Applications/FilesToIpfs.app --args "$@"` in the script window.

Double clicking the resulting Automator file will install it to your system and it will appear in your Services context menu.

## Usage

Select one or more files or folders and right click on the selection. Navigate to Services->FilesToIPFS (or whatever you called the automator script) and select it. Follow the instructions in the window that appears. There is an option to log the added file to a log file of your choosing which will add the hash, the url and the date it was added.

![](ShowFilesToIPFS.gif?raw=true "IPFS native app as a service.")
 
## Todo

## License

MIT
