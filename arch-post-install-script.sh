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

	# Disable pcspeaker sound on boot
	echo "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/nobeep.conf

	sudo mkdir -p /etc/zsh
	echo "export ZDOTDIR=$HOME/.config/zsh" | sudo tee -a /etc/zsh/zshenv

	# Making some directories and exporting variables to easy setup later
	mkdir -p $HOME/.config/{zsh,zim} $HOME/.local/{bin,share} $HOME/.local/share/icons $HOME/{.icons,.themes} $HOME/.var/app
	
	printf '%s\n' \
        'export XDG_CONFIG_HOME=$HOME/.config' \
        'export XDG_CACHE_HOME=$HOME/.cache' \
        'export XDG_DATA_HOME=$HOME/.local/share' \
        'export HISTFILE=$HOME/.config/zsh/zhistory' \
        'export ZIM_HOME=$HOME/.config/zim' >> $HOME/.config/zsh/.zshenv

}

function desktopEnvironmentInstall() {
	printMessage "$1"

	printf "\nPlease, insert the desired desktop environment: hyprland or kde (default kde)\n"
	read desktopEnvironment

	case "$desktopEnvironment" in
        "hyprland")
            printMessage "You choose $desktopEnvironment. Installing environment"
            sudo pacman -S hyprland swaybg hypridle hyprlock waybar rofi-wayland grim slurp dunst gammastep xorg-xwayland wl-clipboard nautilus gnome-epub-thumbnailer polkit-gnome gcr xdg-desktop-portal-gtk xdg-desktop-portal-hyprland sddm pipewire-pulse --noconfirm --needed
            sudo systemctl enable sddm
            GTKENV=true
            ;;

        "kde")
            printMessage "You choose $desktopEnvironment. Installing environment"
            sudo pacman -S plasma dolphin ark spectacle wl-clipboard xdg-desktop-portal-gtk ffmpegthumbs --noconfirm --needed
            sudo systemctl enable sddm
            GTKENV=false
            ;;

        *)
            printMessage "No environment chosen. Installing KDE Plasma as default"
            sudo pacman -S plasma dolphin ark spectacle wl-clipboard xdg-desktop-portal-gtk ffmpegthumbs --noconfirm --needed
            sudo systemctl enable sddm
            GTKENV=false
            ;;
    esac

}

function installPrograms() {
	printMessage "$1"

	sudo pacman -S aria2 bat brightnessctl btop fastfetch fd ffmpegthumbnailer flatpak fzf git git-delta gum gvfs-mtp inxi jq kitty libva-mesa-driver lsd man-db man-pages neovim noto-fonts noto-fonts-cjk noto-fonts-emoji otf-font-awesome poppler power-profiles-daemon p7zip ripgrep rsync starship stow ttf-jetbrains-mono-nerd unzip vulkan-radeon webp-pixbuf-loader wget xdg-user-dirs xdg-utils yazi yt-dlp zoxide zsh --noconfirm --needed

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

	# Grants Flatpak read access to all possible locations for themes and icons inside $HOME directory and Mangohud config read access
	sudo flatpak override --filesystem=~/.themes:ro --filesystem=~/.icons:ro --filesystem=~/.local/share/icons:ro --filesystem=~/.local/share/themes:ro --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro --filesystem=xdg-config/MangoHud:ro --env=XCURSOR_PATH=~/.icons
	
	flatpak install org.mozilla.firefox org.mozilla.Thunderbird org.chromium.Chromium org.telegram.desktop com.discordapp.Discord im.riot.Riot org.libreoffice.LibreOffice org.gnome.papers org.gnome.clocks org.gnome.Calculator io.freetubeapp.FreeTube io.mpv.Mpv io.missioncenter.MissionCenter com.github.johnfactotum.Foliate com.github.finefindus.eyedropper com.usebruno.Bruno com.obsproject.Studio com.valvesoftware.Steam net.minetest.Minetest com.heroicgameslauncher.hgl org.libretro.RetroArch org.freedesktop.Platform.VulkanLayer.MangoHud org.freedesktop.Platform.VulkanLayer.gamescope page.kramo.Cartridges -y
	
	# Grants Freetube access to session bus to be able to open videos on MPV
	sudo flatpak override --socket=session-bus io.freetubeapp.FreeTube

	# Enable Mangohud on Steam Games and grants Steam access to Games directory
	sudo flatpak override --env=MANGOHUD=1 --filesystem=$HOME/Games com.valvesoftware.Steam

	# Enable Wayland support on Thunderbird
	sudo flatpak override --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird

	
	if [[ $GTKENV == true ]]; then {
	    flatpak install com.github.tchx84.Flatseal com.github.hluk.copyq org.flameshot.Flameshot org.gnome.Calendar org.gnome.Loupe org.gnome.Decibels com.saivert.pwvucontrol -y

	    # Enable Wayland support on CopyQ
	    sudo flatpak override --env=QT_QPA_PLATFORM=wayland com.github.hluk.copyq

	    # To Flameshot properly work on Hyprland
	    sudo flatpak override --env=XDG_CURRENT_DESKTOP=sway org.flameshot.Flameshot

	    # For Telegram Pop-ups to work properly
	    sudo flatpak override --env=QT_WAYLAND_DISABLED_INTERFACES=wp_fractional_scale_manager_v1 org.telegram.desktop

	    # Set manually the Chromium Scaling
	    sudo flatpak override --env=GDK_DPI_SCALE=1.25 org.chromium.Chromium

	} else {
	    flatpak install org.kde.gwenview -y

        # Force Steam scaling manually
	    sudo flatpak override --env=STEAM_FORCE_DESKTOPUI_SCALING=1.25 com.valvesoftware.Steam

	}
	fi
	
}

function devEnvironmentSetup() {
	printMessage "$1"

	printf "\nInstalling Mise version manager, nodeJS, pnpm and shellcheck\n"

    # Mise installation and activation to use now
	curl https://mise.run | sh
    echo "eval \"\$($HOME/.local/bin/mise activate zsh)\"" >> "$HOME/.config/zsh/.zshrc"
    mise activate bash

    # Mise and pnpm completions and Mise plugins installation
    mise completion zsh >> "$HOME/.config/zsh/.zshrc"
    mise use -g -y usage node@20 pnpm shellcheck
    pnpm setup

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

    if [[ $GTKENV == true ]]; then {
        # Install GTK, icon and cursor themes
        cd $HOME
        curl -L -O "$(curl "https://api.github.com/repos/lassekongo83/adw-gtk3/releases" | jq -r '.[0].assets[0].browser_download_url')"
        tar -xvf adw-gtk3v*.tar.xz;
        rm -rf adw-gtk3v*.tar.xz;
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

    } else {
        cd $HOME
        sudo pacman -Syu git jq wget unzip qt6-svg qt6-declarative --noconfirm --needed
        git clone https://github.com/vinceliuice/Tela-circle-icon-theme; cd Tela-circle-icon-theme/; ./install.sh

        curl -L -O "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz"; 
        tar -xvf Bibata-Modern-Ice.tar.xz; mv Bibata-Modern-Ice $HOME/.local/share/icons/

        git clone --depth=1 https://github.com/catppuccin/kde catppuccin-kde && cd catppuccin-kde; ./install.sh;

        curl -L -O "$(curl "https://api.github.com/repos/catppuccin/sddm/releases" | jq -r '.[0].assets[3].browser_download_url')"; sudo mv catppuccin-mocha /usr/share/sddm/themes/
        ln -s ~/.local/share/icons/ ~/.icons
        sudo ln -sf ~/.local/share/icons/Bibata-Modern-Ice /usr/share/icons/Bibata-Modern-Ice; sudo ln -sf ~/.local/share/icons/Tela-circle /usr/share/icons/Tela-circle; sudo ln -sf ~/.local/share/icons/Tela-circle-light /usr/share/icons/Tela-circle-light; sudo ln -sf ~/.local/share/icons/Tela-circle-dark /usr/share/icons/Tela-circle-dark
        cd $HOME

    }
    fi

    # Yazi catppuccin-mocha theme installation
    ya pack -a "yazi-rs/flavors#catppuccin-mocha"

	# Cleanup
	rm -rf Tela-circle-icon-theme Bibata-Modern-Ice.tar.xz .npm
	rm .bashrc .bash_profile .bash_logout .bash_history
	sudo pacman -Rn gnu-free-fonts --noconfirm

	# Activate conservation mode on Ideapad laptops
	echo 1 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode

	# Enable power-profiles-daemon
	sudo systemctl enable power-profiles-daemon

	# Change shell to ZSH
	chsh -s /usr/bin/zsh
	sudo chsh -s /usr/bin/zsh
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

enableZRAM "Enabling and configuring ZRAM"

printMessage "Please, reboot system to apply changes"


# Some useful packages list:

# azote exfat-utils usbutils copyq yazi gdu cmus opus-tools otf-font-awesome inxi ecm-tools kdeconnect dmidecode dupeguru p7zip-full unrar timeshift ytfzf hdsentinel nwg-look-bin wf-recorder qt5ct qt5-styleplugins


# More information:

# https://wiki.archlinux.org/title/Zram
# https://gist.github.com/jwebcat/5122366
