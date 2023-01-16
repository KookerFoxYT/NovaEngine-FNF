# Nova Engine
funny fnf rewrite

beat batle

<details>
  <summary><h2>How to build</h2></summary>

> **Open the instructions for your platform**
<details>
    <summary>Windows</summary>

##### Tested on Windows 10 21H2
1. Install the [latest version of Haxe](https://haxe.org/download/).
2. Download [Visual Studio Build Tools](https://aka.ms/vs/17/release/vs_BuildTools.exe)
3. Wait for the Visual Studio Installer to install
4. On the Visual Studio installer screen, go to the "Individual components" tab and only select those options:
    - MSVC v143 VS 2022 C++ x64/x86 build tools (Latest)
    - Windows 10/11 SDK (any works)
5. This is what your Installation details panel should look like. Once correct, press "Install".
    - ⚠ This will download around 1.07 GB of data from the internet, and will require around 5.5 GB of available space on your computer.

<p align="center">
<img src="https://github.com/YoshiCrafter29/CodenameEngine/blob/main/art/github/windows-installation-details.png?raw=true" />
</p>

6. Once the installation is done, close Visual Studio Installer.
7. Download and install [`git-scm`](https://git-scm.com/download/win).
    - Leave all installation options as default.
8. Open the Nova Engine source folder, click on the address bar and type `cmd` to open a command prompt window.
9. On the command prompt, run `update.bat`, and wait for the libraries to install.
10. Once the libraries are installed, run `haxelib run lime test windows` to compile and launch the game (may take a long time)
    - ℹ You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test windows` directly.
</details>
<details>
    <summary>Linux</summary>

1. Install the [latest version of Haxe](https://haxe.org/download/).
2. Install `g++`, if not present already.
3. Download and install [`git-scm`](https://git-scm.com/download/linux).
4. Open a terminal in the Nova Engine source folder, and run `update.sh`.
5. Once the libraries are installed, run `haxelib run lime test linux` to compile and launch the game (may take a long time)
    - ℹ You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test linux` directly.
</details>
<details>
    <summary>MacOS</summary>

##### Requires testing
1. Install the [latest version of Haxe](https://haxe.org/download/).
2. Install `Xcode` to allow C++ app building.
3. Download and install [`git-scm`](https://git-scm.com/download/mac).
4. Open a terminal in the Nova Engine source folder, and run `update.sh`.
5. Once the libraries are installed, run `haxelib run lime test mac` to compile and launch the game (may take a long time)
    - ℹ You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test mac` directly.

</details>
</details>