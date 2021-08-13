#!/bin/bash

cd "$(dirname "$0")" || exit 1

if [ -n "$(which cmake)" ]; then
	cmake -P CMakeBBLM.cmake
elif [ -x /Applications/CMake.app/Contents/bin/cmake ]; then
	/Applications/CMake.app/Contents/bin/cmake -P CMakeBBLM.cmake
else
	echo "CMake is not installed." >&2
	exit 1
fi

if [ -d ~/Dropbox/Application\ Support/BBEdit ]; then
	mkdir -v -p ~/Dropbox/Application\ Support/BBEdit/Language\ Modules
	cp -f -v cmake.plist ~/Dropbox/Application\ Support/BBEdit/Language\ Modules
else
	mkdir -v -p ~/Library/Application\ Support/BBEdit/Language\ Modules
	cp -f -v cmake.plist ~/Library/Application\ Support/BBEdit/Language\ Modules
fi

echo "CMake BBEdit language module installed. Please restart BBEdit."
