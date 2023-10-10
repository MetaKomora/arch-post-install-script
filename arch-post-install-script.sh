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
	sudo reflector --country Sweden,United_States --protocol https --latest 5 --save /etc/pacman.d/mirrorlist

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
	
}

function setVariables() {
	snapshotsdir=""
	
	printf "\nPlease, insert your snapshots directory (leave empty to skip snapshots creation):\n"
	read snapshotsdir

	printf "\nPlease, insert the desired desktop environment: xfce, i3, sway or gnome (default sway)\n"
	read desktopEnvironment

	[[ -z $desktopEnvironment ]] && {
		#If nothing is passed, default to sway
		desktopEnvironment="sway"
	}
}

function desktopEnvironmentInstall() {
	printMessage "$1"

	[[ $desktopEnvironment == "gnome" ]] && {
		printMessage "You choose $desktopEnvironment. Installing environment"
		sudo pacman -S gdm gnome-control-center gnome-tweaks wl-clipboard --noconfirm --needed
		sudo systemctl enable gdm
	}

	[[ $desktopEnvironment == "sway" ]] && {
		printMessage "You choose $desktopEnvironment. Installing environment"
		sudo pacman -S sway swaybg waybar rofi grim slurp mako gammastep xorg-xwayland wl-clipboard xdg-desktop-portal-gtk xdg-desktop-portal-wlr ly --noconfirm --needed
		sudo systemctl enable ly

		# Disable pcspeaker sound on boot when using ly display manager
		echo "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/nobeep.conf
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

    [[ $desktopEnvironment == "sway" ]] && {
        # Some Wayland programs reads the current desktop variable to identify sway properly
        printf "export XDG_CURRENT_DESKTOP=sway\n" >> $HOME/.config/zsh/.zshenv

        # Remove minimize, maximize and close buttons from programs with CSD
        gsettings set org.gnome.desktop.wm.preferences button-layout ""
    }
}

function installPrograms() {
	printMessage "$1"

	sudo pacman -S android-tools aria2 bat btop ffmpegthumbnailer file-roller flatpak gdu glow gnome-disk-utility gvfs-mtp inxi jq libva-intel-driver lsd man-db nautilus neofetch noto-fonts noto-fonts-cjk noto-fonts-emoji podman-compose podman-docker polkit-gnome rsync starship stow ttf-jetbrains-mono-nerd xdg-user-dirs xdg-utils yad yt-dlp zsh --noconfirm --needed
	
	flatpak install org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark gradience flatseal org.mozilla.firefox org.mozilla.Thunderbird org.chromium.Chromium org.telegram.desktop webcord flameshot org.libreoffice.LibreOffice clocks org.gnome.Calculator evince org.gnome.Calendar org.gnome.Loupe decibels freetube io.mpv.Mpv missioncenter pavucontrol foliate eyedropper insomnia kooha com.raggesilver.BlackBox com.valvesoftware.Steam minetest -y
	
	# Grants Telegram access to $HOME directory to be able to send files in-app
	sudo flatpak override --filesystem=home org.telegram.desktop
	# Grants access to themes and icons inside $HOME directory to set the GTK theme but without forcing it
	sudo flatpak override --filesystem=~/.themes --filesystem=~/.icons --filesystem=xdg-config/gtk-3.0 --filesystem=xdg-config/gtk-4.0
	# Grants MPV access to XCURSOR_PATH environment variable to use cursor theme
	sudo flatpak override --env=XCURSOR_PATH=~/.icons io.mpv.Mpv

	# Enable Wayland support on Firefox and Thunderbird
	sudo flatpak override --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox
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
	git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch v0.11.3
	. $HOME/.config/asdf/asdf.sh
	asdf plugin add nodejs && asdf install nodejs latest:20 && asdf global nodejs latest:20
	asdf plugin add shellcheck && asdf install shellcheck latest && asdf global shellcheck latest


	# To search Docker images on docker.io with Podman without using full image link
	sudo mkdir -p /etc/containers/registries.conf.d
	echo 'unqualified-search-registries=["docker.io"]' | sudo tee -a /etc/containers/registries.conf.d/docker.conf
	
}

function userEnvironmentSetup() {
	printMessage "$1"

	# Setting XDG directories and some default applications
	xdg-user-dirs-update
	xdg-mime default nvim.desktop text/plain
	xdg-mime default nvim.desktop text/markdown
	xdg-mime default nvim.desktop application/x-shellscript
	xdg-mime default org.gnome.Loupe.desktop image/png
	xdg-mime default org.gnome.Loupe.desktop image/jpeg
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
	curl -L -O "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.gz"
	tar -xvf Bibata-Modern-Ice.tar.gz
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
	gsettings set org.gtk.Settings.FileChooser window-size "(1100, 670)"
	gsettings set org.gtk.Settings.FileChooser sort-directories-first true
	gsettings set org.gtk.Settings.FileChooser show-hidden true
	gsettings set org.gtk.gtk4.Settings.FileChooser window-size "(1100, 670)"
	gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
	gsettings set org.gtk.gtk4.Settings.FileChooser show-hidden true

	# Cleanup
	rm -rf adw-gtk3v*.tar.xz Tela-circle-icon-theme Bibata-Modern-Ice.tar.gz .npm
	sudo pacman -Rn gnu-free-fonts --noconfirm

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
	echo "/dev/zram0 none swap defaults 0 0" | sudo tee -a /etc/fstab
	
	# Alter swappiness priority to 5
	echo "vm.swappiness = 5" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
}


# --------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------- #
# -------------------------------------Executing functions------------------------------------- #
# --------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------- #

initialSystemSetup "Change mirrors branch if needed, upgrade system and installs basic programs"

setVariables

desktopEnvironmentInstall "Installing Desktop Environment"

installPrograms "Installing Programs"

devEnvironmentSetup "Installing development tools"

userEnvironmentSetup "Setting default applications, installing themes and making cleanups"

desktopEnvironmentSetup "Setting specific environment configurations"

enableZRAM "Enabling and configuring ZRAM"


# If there is a BTRFS snapshots subvolume dir in the variable, create a snapshot and update GRUB
[[ -d "$snapshotsdir" ]] && {
	sudo mkdir "$snapshotsdir"/{@,@home}
	sudo btrfs subvolume snapshot / "$snapshotsdir"/@/post_install__-__"$(date '+%d-%m-%Y_-_%R')"
	sudo btrfs subvolume snapshot /home "$snapshotsdir"/@home/post_install__-__"$(date '+%d-%m-%Y_-_%R')"
	sudo update-grub
}


printMessage "Please, reboot system to apply changes"

############################
##### Optional programs ####
############################
# alacarte azote fsearch-git catfish mlocate exfat-utils usbutils deadd-notification-center-bin xfce4-clipman-plugin copyq polybar calibre zeal nnn bat lsd cmus figlet opus-tools pulseaudio-alsa otf-font-awesome gpick gcolor3 audacity inxi mangohud lib32-mangohud ecm-tools lutris wine-staging discord kdeconnect udiskie gparted dmidecode gdu baobab gnome-font-viewer dbeaver dupeguru screenkey soundconverter p7zip-full unrar selene-media-converter timeshift xdman persepolis deluge-gtk ytfzf-git fzf ueberzug zenity hdsentinel font-manager gucharmap nwg-look-bin wmctrl gnome-epub-thumbnailer wf-recorder qt5ct qt5-styleplugins hardinfo appimagelauncher


# More information:

# https://wiki.archlinux.org/index.php/Improving_performance#Zram_or_zswap
# https://unix.stackexchange.com/questions/453585/shell-script-to-comment-and-uncomment-a-line-in-file
# https://linuxize.com/post/how-to-add-directory-to-path-in-linux/
# https://diolinux.com.br/2019/09/remover-ruido-do-microfone-no-linux.html
# https://www.linuxuprising.com/2020/09/how-to-enable-echo-noise-cancellation.html
# https://wiki.manjaro.org/index.php/Set_all_Qt_app%27s_to_use_GTK%2B_font_%26_theme_settings
# https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
# https://gist.github.com/jwebcat/5122366
