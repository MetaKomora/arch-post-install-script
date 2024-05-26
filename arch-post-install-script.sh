#!/bin/bash

function printMessage() {
	printf "\n\n\e[032;1m$1\e[m\n\n"; sleep 2;
}

function initialSystemSetup() {
	printMessage "$1"
	
	# Enable network time synchronization
	sudo timedatectl set-ntp true

	# Change mirrorlist
	sudo pacman -Syyu reflector --noconfirm --needed
	sudo reflector --country Sweden,United_States,Canada --protocol https --sort rate --save /etc/pacman.d/mirrorlist

	# Uncommenting some options on Pacman config
	sudo sed -i -e 's/#Color/Color/' -e 's/#VerbosePkgLists/VerbosePkgLists/' -e 's/#ParallelDownloads = 5/ParallelDownloads = 20\nILoveCandy/' /etc/pacman.conf

	sudo pacman -Syyu neovim pipewire-pulse wireplumber git brightnessctl --noconfirm --needed
 
	# Install yay-bin from AUR
	printMessage "Do you want install Yay AUR helper?"
	read answerAUR

	if [[ "$answerAUR" == "y" ]] || [[ "$answerAUR" == "Y" ]]; then {
	    sudo pacman -S base-devel --noconfirm --needed
	    cd $HOME
	    git clone https://aur.archlinux.org/yay-bin.git
	    cd yay-bin
	    makepkg -si --noconfirm --needed
	    cd $HOME
	    rm -rf yay-bin
	}
	fi

	# Making some directories and exporting variables to easy setup later
	mkdir -p $HOME/.config/{zsh,zim} $HOME/.local/{bin,share} $HOME/{.icons,.themes} $HOME/.var/app
	sudo mkdir -p /etc/zsh

	echo "export ZDOTDIR=$HOME/.config/zsh" | sudo tee -a /etc/zsh/zshenv
	printf 'export XDG_CONFIG_HOME=$HOME/.config\n' >> $HOME/.config/zsh/.zshenv
	printf 'export XDG_CACHE_HOME=$HOME/.cache\n' >> $HOME/.config/zsh/.zshenv
	printf 'export XDG_DATA_HOME=$HOME/.local/share\n' >> $HOME/.config/zsh/.zshenv
	printf 'export HISTFILE=$HOME/.config/zsh/zhistory\n' >> $HOME/.config/zsh/.zshenv
	printf 'export ZIM_HOME=$HOME/.config/zim\n' >> $HOME/.config/zsh/.zshenv

	# Disable pcspeaker sound on boot
	echo "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/nobeep.conf
	
}

function desktopEnvironmentInstall() {
	printMessage "$1"

	printf "\nPlease, insert the desired desktop environment: sway, gnome or hyprland (default sway)\n"
	read desktopEnvironment

	[[ -z $desktopEnvironment ]] && {
		#If nothing is passed, default to sway
		desktopEnvironment="sway"
	}


	[[ $desktopEnvironment == "gnome" ]] && {
		printMessage "You choose $desktopEnvironment. Installing environment"
		sudo pacman -S gdm gnome-control-center gnome-tweaks wl-clipboard --noconfirm --needed
		sudo systemctl enable gdm
	}

	[[ $desktopEnvironment == "sway" ]] && {
		printMessage "You choose $desktopEnvironment. Installing environment"
		sudo pacman -S sway swaybg swaylock waybar wofi grim slurp mako gammastep xorg-xwayland wl-clipboard xdg-desktop-portal-gtk xdg-desktop-portal-wlr ly --noconfirm --needed
		sudo systemctl enable ly
	}

	[[ $desktopEnvironment == "hyprland" ]] && {
	    printMessage "You choose $desktopEnvironment. Installing environment"
	    sudo pacman -S hyprland swaybg swaylock waybar wofi grim slurp mako gammastep xorg-xwayland wl-clipboard xdg-desktop-portal-gtk xdg-desktop-portal-hyprland --noconfirm --needed
	}

}

function desktopEnvironmentSetup() {
    printMessage "$1"

    [[ $desktopEnvironment == "gnome" ]] && {
        # Set keyboard layout
        gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'br')]"

        # Mouse and Touchpad configurations
        gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
        gsettings set org.gnome.desktop.peripherals.touchpad speed 0.85
        gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
        gsettings set org.gnome.desktop.peripherals.mouse speed 0.5

        # Open Nautilus maximized
        gsettings set org.gnome.nautilus.window-state maximized true

        # Set 4 static workspaces
        gsettings set org.gnome.mutter dynamic-workspaces false
        gsetinggs set org.gnome.desktop.wm.preferences num-workspaces 4

        # alt+tab switch between programs only on current workspace
        gsettings set org.gnome.shell.app-switcher current-workspace-only true

        # Set keyboard shortcuts to workspaces
        gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 ['<Shift><Super>exclam']
        gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 ['<Shift><Super>at']
        gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 ['<Shift><Super>numbersign']
        gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 ['<Shift><Super>dollar']
        gsettings set org.gnome.desktop.wm.keybindings show-desktop ['<Primary><Alt>d']
    }
}

function installPrograms() {
	printMessage "$1"

	sudo pacman -S aria2 bat btop fastfetch ffmpegthumbnailer flatpak fzf gnome-epub-thumbnailer gvfs-mtp inxi jq libnotify libva-mesa-driver lsd man-db nautilus noto-fonts noto-fonts-cjk noto-fonts-emoji otf-font-awesome polkit-gnome power-profiles-daemon rsync starship stow ttf-jetbrains-mono-nerd vulkan-radeon webp-pixbuf-loader xdg-user-dirs xdg-utils yad yt-dlp zoxide zsh --noconfirm --needed
	
	flatpak install org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark gradience flatseal org.mozilla.firefox org.mozilla.Thunderbird org.chromium.Chromium copyq org.telegram.desktop discord flameshot org.libreoffice.LibreOffice clocks org.gnome.Calculator evince org.gnome.Calendar org.gnome.Loupe decibels freetube io.mpv.Mpv missioncenter pavucontrol foliate eyedropper postman kooha com.raggesilver.BlackBox com.valvesoftware.Steam minetest -y
	
	# Grants Flatpak access to themes and icons inside $HOME directory to set the GTK theme
	sudo flatpak override --filesystem=~/.themes --filesystem=~/.icons --filesystem=xdg-config/gtk-3.0 --filesystem=xdg-config/gtk-4.0
	
	# Grants MPV access to XCURSOR_PATH environment variable to use cursor theme
	sudo flatpak override --env=XCURSOR_PATH=~/.icons io.mpv.Mpv
	
	# Grants Freetube access to session bus to be able to open videos on MPV
	sudo flatpak override --socket=session-bus io.freetubeapp.FreeTube

	# Makes Copyq open via Xwayland to work properly
	sudo flatpak override --env=QT_QPA_PLATFORM=xcb com.github.hluk.copyq

	# Enable Wayland support on Thunderbird
	sudo flatpak override --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird
	
}

function devEnvironmentSetup() {
	printMessage "$1"

	printf "\nInstalling ASDF version manager, nodeJS and shellcheck\n"

	# Export ASDF variables temporarily to use ASDF commands now
	export ASDF_CONFIG_FILE="$HOME/.config/asdf/asdfrc"
	export ASDF_DIR="$HOME/.config/asdf"
	export ASDF_DATA_DIR="$HOME/.local/state/asdf"
	export ASDF_DEFAULT_TOOL_VERSIONS_FILENAME=".config/asdf/.tool-versions"

	# Properly exporting ASDF variables to zshrc
	printf '\n# ASDF version manager' >> $HOME/.config/zsh/.zshrc
	printf '\nexport ASDF_CONFIG_FILE="$HOME/.config/asdf/asdfrc"' >> $HOME/.config/zsh/.zshrc
	printf '\nexport ASDF_DIR="$HOME/.config/asdf"' >> $HOME/.config/zsh/.zshrc
	printf '\nexport ASDF_DATA_DIR="$HOME/.local/state/asdf"' >> $HOME/.config/zsh/.zshrc
	printf '\nexport ASDF_DEFAULT_TOOL_VERSIONS_FILENAME=".config/asdf/.tool-versions"' >> $HOME/.config/zsh/.zshrc
	printf '\n. $HOME/.config/asdf/asdf.sh' >> $HOME/.config/zsh/.zshrc

	# Adding ASDF completions to zshrc
	printf '\n\n# append ASDF completions to fpath\nfpath=(${ASDF_DIR}/completions $fpath)\n# initialise completions with ZSH compinit\nautoload -Uz compinit && compinit\n' >> $HOME/.config/zsh/.zshrc

	# ASDF and plugins installation
	git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch v0.14.0
	. $HOME/.config/asdf/asdf.sh
	asdf plugin add nodejs && asdf install nodejs latest:20 && asdf global nodejs latest:20
	asdf plugin add shellcheck && asdf install shellcheck latest && asdf global shellcheck latest
}

function userEnvironmentSetup() {
	printMessage "$1"

	# Setting XDG directories and some default applications
	xdg-user-dirs-update
	xdg-mime default org.gnome.Loupe.desktop image/png
	xdg-mime default org.gnome.Loupe.desktop image/jpeg
	xdg-mime default org.gnome.Loupe.desktop image/webp
	xdg-mime default org.gnome.Evince.desktop application/pdf
	xdg-mime default org.mozilla.firefox.desktop x-scheme-handler/http
	xdg-mime default org.mozilla.firefox.desktop x-scheme-handler/https

	# Install GTK, icon and cursor themes
	cd $HOME
	curl -L -O "$(curl "https://api.github.com/repos/lassekongo83/adw-gtk3/releases" | jq -r '.[0].assets[0].browser_download_url')"
	tar -xvf adw-gtk3v*.tar.xz;
	mv adw-gtk3 adw-gtk3-dark $HOME/.themes
	git clone https://github.com/vinceliuice/Tela-circle-icon-theme
	cd Tela-circle-icon-theme; ./install.sh -d $HOME/.icons; cd ../
	curl -L -O "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz"
	tar -xvf Bibata-Modern-Ice.tar.xz
	mv Bibata-Modern-Ice $HOME/.icons
	cd $HOME

	# Themes configuration
	gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
	gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-dark'
	gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'
	gsettings set org.gnome.desktop.wm.preferences theme "adw-gtk3-dark"

	# Font Configuration
	gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'
	gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 11'
	gsettings set org.gnome.desktop.interface monospace-font-name 'Noto Sans Mono 10'
	gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Bold 11'

	# GTK FileChooser configuration
	gsettings set org.gtk.Settings.FileChooser sort-directories-first true
	gsettings set org.gtk.Settings.FileChooser show-hidden true
	gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
	gsettings set org.gtk.gtk4.Settings.FileChooser show-hidden true

	# Cleanup
	rm -rf adw-gtk3v*.tar.xz Tela-circle-icon-theme Bibata-Modern-Ice.tar.xz .npm
	rm .bashrc .bash_profile .bash_logout .bash_history
	sudo pacman -Rn gnu-free-fonts --noconfirm

	# Activate conservation mode on Ideapad laptops
	echo 1 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode

	# Enable power-profiles-daemon
	sudo systemctl enable power-profiles-daemon

	# Change shell to ZSH
	chsh -s /bin/zsh
	sudo chsh -s /bin/zsh
	source $HOME/.config/zsh/.zshenv

	# Downloading Zim Framework
	curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
}

function enableZRAM() {

	printMessage "$1"
	
	# Enable zram module
	sudo sed -i "s/MODULES=()/MODULES=(zram)/" /etc/mkinitcpio.conf
	echo "zram" | sudo tee -a /etc/modules-load.d/zram.conf
	
	# Create a udev rule. Change ATTR{disksize} to your needs
	echo 'ACTION=="add", KERNEL=="zram0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="4G", RUN="/usr/bin/mkswap -U clear /dev/%k", TAG+="systemd"' | sudo tee -a /etc/udev/rules.d/99-zram.rules
	
	# Add /dev/zram to your fstab
	echo "/dev/zram0 none swap defaults,pri=100 0 0" | sudo tee -a /etc/fstab
	
	# Optimizing swap on zram
	printf "vm.swappiness = 180\nvm.watermark_boost_factor = 0\nvm.watermark_scale_factor = 125\nvm.page-cluster = 0" | sudo tee -a /etc/sysctl.d/99-vm-zram-parameters.conf
}


# --------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------- #
# -------------------------------------Executing functions------------------------------------- #
# --------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------- #

initialSystemSetup "Change mirrors branch if needed, upgrade system and installs basic programs"

desktopEnvironmentInstall "Installing Desktop Environment"

installPrograms "Installing Programs"

devEnvironmentSetup "Installing development tools"

userEnvironmentSetup "Setting default applications, installing themes and making cleanups"

desktopEnvironmentSetup "Setting specific environment configurations"

enableZRAM "Enabling and configuring ZRAM"

printMessage "Please, reboot system to apply changes"


# Some useful packages list:

# azote exfat-utils usbutils copyq yazi gdu cmus opus-tools otf-font-awesome inxi ecm-tools kdeconnect dmidecode dupeguru p7zip-full unrar timeshift ytfzf hdsentinel nwg-look-bin wf-recorder qt5ct qt5-styleplugins


# More information:

# https://wiki.archlinux.org/title/Zram
# https://gist.github.com/jwebcat/5122366
