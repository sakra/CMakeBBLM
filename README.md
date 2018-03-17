CMakeBBLM
=========

CMakeBBLM is a script that generates a [BBEdit codeless language module][clm] for [CMake][cmake].

Features
--------

* Dynamically generates a BBEdit codeless language module for the actual CMake version installed.
* Supports text completion for CMake built-in commands, properties and variables.
* Supports BBEdit function pop-ups for user-defined CMake functions and macros.

Requirements
------------

* BBEdit 10 or newer.
* CMake 2.8.12 or newer.

Installation
------------

Execute the shell script `install.sh` with Terminal.app to generate and install the BBEdit language
module:

    $ ./install.sh
    cmake.plist -> /Users/sakra/Dropbox/Application Support/BBEdit/Language Modules/cmake.plist
    CMake BBEdit language module installed. Please restart BBEdit.

The generated module is tailored to the version of CMake installed on the system, i.e., it will
only support keywords and predefined names valid for that version.

The install script copies the generated language module to BBEdit's application support folder in
the Dropbox data folder or in the user's Library folder.

Usage
-----

Restart BBEdit after installation. The language `CMake` is then available in an editor window's
language popup menu. The `CMakeBBLM` module is automatically used for files named `CMakeLists.txt`
and for files with the extensions `.cmake` or `.ctest`.

[clm]:https://www.barebones.com/support/develop/clm.html
[cmake]:https://cmake.org/
