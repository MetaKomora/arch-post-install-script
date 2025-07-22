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
    sudo reflector --country Sweden,United_States --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    printf "\n\n\n\n"

    # Uncommenting some options on Pacman config
    sudo sed -i -e 's/#Color/Color/' -e 's/#VerbosePkgLists/VerbosePkgLists/' -e 's/ParallelDownloads = 5/ParallelDownloads = 10\nILoveCandy/' /etc/pacman.conf

    # Disable pcspeaker sound on boot
    echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf;

    # Set $ZDOTDIR variable to $HOME/.config/zsh instead of $HOME
    sudo mkdir -pv /etc/zsh
    echo "export ZDOTDIR=$HOME/.config/zsh" | sudo tee /etc/zsh/zshenv

    # Making some directories and exporting variables to easy setup later
    mkdir -pv $HOME/.config/{zsh,zim} $HOME/.local/{bin,share} $HOME/.icons/default $HOME/.local/share/icons $HOME/.var/app 
	
    printf '%s\n' \
        'export GDK_SCALE=1.25' \
        'export XDG_CONFIG_HOME=$HOME/.config' \
        'export XDG_CACHE_HOME=$HOME/.cache' \
        'export XDG_DATA_HOME=$HOME/.local/share' \
        'export HISTFILE=$HOME/.config/zsh/zhistory' \
        'export ZIM_HOME=$HOME/.config/zim' >> $HOME/.config/zsh/.zshrc

}

function desktopEnvironmentInstall() {
    printMessage "$1"

    printf "\nPlease, insert the desired desktop environment: hyprland or kde (default kde)\n"
    read desktopEnvironment

    case "$desktopEnvironment" in
        "hyprland")
            printMessage "You choose $desktopEnvironment. Installing environment"
            sudo pacman -S hyprland swaybg azote nwg-look hypridle hyprlock waybar rofi-wayland cliphist hyprpicker grim slurp dunst hyprsunset wl-clipboard nautilus gnome-epub-thumbnailer hyprpolkitagent udiskie libappindicator-gtk3 network-manager-applet xdg-desktop-portal-gtk xdg-desktop-portal-hyprland sddm pipewire-pulse qt5-wayland --noconfirm --needed
            GTKENV=true
            ;;

        "kde")
            printMessage "You choose $desktopEnvironment. Installing environment"
            sudo pacman -S plasma dolphin ark spectacle wl-clipboard xdg-desktop-portal-gtk ffmpegthumbs --noconfirm --needed
            GTKENV=false
            ;;

        *)
            printMessage "No environment chosen. Installing KDE Plasma as default"
            sudo pacman -S plasma dolphin ark spectacle wl-clipboard xdg-desktop-portal-gtk ffmpegthumbs --noconfirm --needed
            GTKENV=false
            ;;
    esac

}

function installPrograms() {
    printMessage "$1"

    sudo pacman -S 7zip adwaita-fonts adw-gtk-theme aria2 bat brightnessctl btop fastfetch fd ffmpegthumbnailer flatpak fzf gcr gdu git git-delta gnupg gum gvfs-mtp inxi jq kitty libnotify lsd man-db man-pages mise neovim noto-fonts noto-fonts-cjk noto-fonts-emoji openssh otf-font-awesome poppler ripgrep rsync starship stow tealdeer tela-circle-icon-theme-standard ttf-jetbrains-mono-nerd tuned-ppd unzip usage vulkan-radeon webp-pixbuf-loader wget xdg-user-dirs xdg-utils yad yazi yt-dlp zellij zoxide zsh --noconfirm --needed

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
        rm -rfv yay-bin
    }
    fi

    # Grants Flatpak read access to all possible locations for themes and icons inside $HOME directory and Mangohud config read access
    sudo flatpak override --filesystem=~/.themes:ro --filesystem=~/.icons:ro --filesystem=~/.local/share/icons:ro --filesystem=~/.local/share/themes:ro --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro --filesystem=xdg-config/MangoHud:ro --env=XCURSOR_PATH=~/.icons
	
    flatpak install org.mozilla.firefox app.zen_browser.zen org.mozilla.Thunderbird org.telegram.desktop com.valvesoftware.Steam io.freetubeapp.FreeTube org.gnome.Papers org.gnome.Loupe be.alexandervanhee.gradia -y

    flatpak install org.chromium.Chromium im.riot.Riot org.libreoffice.LibreOffice org.gnome.clocks org.gnome.Calculator org.gnome.Calendar io.mpv.Mpv com.github.tchx84.Flatseal page.codeberg.libre_menu_editor.LibreMenuEditor com.saivert.pwvucontrol io.missioncenter.MissionCenter org.gabmus.gfeeds com.github.johnfactotum.Foliate io.github.josephmawa.Bella com.usebruno.Bruno com.obsproject.Studio org.qbittorrent.qBittorrent org.luanti.luanti page.kramo.Cartridges net.lutris.Lutris com.heroicgameslauncher.hgl org.libretro.RetroArch org.freedesktop.Platform.VulkanLayer.MangoHud//23.08 org.freedesktop.Platform.VulkanLayer.gamescope//23.08 -y
	
    # Grants Freetube access to session bus to be able to open videos on MPV
    sudo flatpak override --talk-name=org.freedesktop.Flatpak io.freetubeapp.FreeTube

    # Enable Mangohud on Steam Flatpak games and grants Steam Flatpak access to Games directory
    sudo flatpak override --env=MANGOHUD=1 --filesystem=$HOME/Games com.valvesoftware.Steam

    # Enable Wayland support on Thunderbird
    sudo flatpak override --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird

    # Enable Wayland support on Chromium which allows it to auto scale correctly on HiDPI displays
    mkdir -pv $HOME/.var/app/org.chromium.Chromium/config/
    echo "--ozone-platform-hint=auto" | tee $HOME/.var/app/org.chromium.Chromium/config/chromium-flags.conf
	
    if [[ $GTKENV == true ]]; then {
        # For Telegram Pop-ups to work properly on Hyprland
        sudo flatpak override --env=QT_WAYLAND_DISABLED_INTERFACES=wp_fractional_scale_manager_v1 org.telegram.desktop
    }
    fi
}

function devEnvironmentSetup() {
    printMessage "$1"

    printf "\nInstalling Mise version manager packages: nodeJS, pnpm and shellcheck\n"

    # Mise activation
    echo "eval \"\$(/usr/bin/mise activate zsh)\"" >> "$HOME/.config/zsh/.zshrc"

    # Mise and pnpm completions and Mise plugins installation
    /usr/bin/mise completion zsh >> "$HOME/.config/zsh/.zshrc"
    /usr/bin/mise use -g -y node@22 pnpm shellcheck@0.9.0
    #pnpm setup # Manually use the command later, until proper fix

}

function userEnvironmentSetup() {
    printMessage "$1"

    # Setting XDG directories and some default applications
    xdg-user-dirs-update
    xdg-mime default org.gnome.Papers.desktop application/pdf
    xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/webp
    xdg-mime default app.zen_browser.zen.desktop x-scheme-handler/http x-scheme-handler/https

    # Downloading and extracting cursor theme
    cd $HOME
    curl -L -O "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz"
    tar -xvf Bibata-Modern-Ice.tar.xz

    if [[ $GTKENV == true ]]; then {

        mv -v $HOME/Bibata-Modern-Ice $HOME/.icons
        cd $HOME

        # GTK FileChooser configuration
        gsettings set org.gtk.Settings.FileChooser sort-directories-first true
        gsettings set org.gtk.Settings.FileChooser show-hidden true
        gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
        gsettings set org.gtk.gtk4.Settings.FileChooser show-hidden true

    } else {

        mv -v $HOME/Bibata-Modern-Ice $HOME/.local/share/icons
        cd $HOME
        printf "[Icon Theme]\nName=Default\nComment=Default Cursor Theme\nInherits=Bibata-Modern-Ice" | tee $HOME/.icons/default/index.theme

        git clone --depth=1 https://github.com/catppuccin/kde catppuccin-kde && cd catppuccin-kde; ./install.sh;
        cd $HOME
        rm -rfv catppuccin-kde
        ln -s ~/.local/share/icons/* ~/.icons

    }
    fi

    # Yazi catppuccin-mocha flavor installation
    mkdir -pv ~/.config/yazi/
    curl https://raw.githubusercontent.com/catppuccin/yazi/refs/heads/main/themes/mocha/catppuccin-mocha-blue.toml -o ~/.config/yazi/theme.toml

    # Cleanup
    rm -rfv .npm
    rm -v Bibata-Modern-Ice.tar.xz .bashrc .bash_profile .bash_logout .bash_history

    echo "eval \"\$(starship init zsh)\"" >> "$HOME/.config/zsh/.zshrc"
	
}

function systemTweaks() {
    printMessage "$1"

    # Activate conservation mode on Ideapad laptops
    echo 1 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode

    # Enable tuned and tuned-ppd
    sudo systemctl enable tuned tuned-ppd

    # Remove gnu-free-fonts since noto-fonts is already installed
    sudo pacman -Rn gnu-free-fonts --noconfirm
	
    # if zram-generator is not installed, setup zram udev rule
    if [[ $(pacman -Qq zram-generator 2>/dev/null) != "zram-generator" ]]; then {
        # Enable zram module
        sudo sed -i "s/MODULES=()/MODULES=(zram)/" /etc/mkinitcpio.conf
        echo "zram" | sudo tee /etc/modules-load.d/zram.conf
	
        # Create a udev rule. Change ATTR{disksize} to your needs
        echo 'ACTION=="add", KERNEL=="zram0", ATTR{initstate}=="0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="4700M", RUN="/usr/bin/mkswap -U clear %N", TAG+="systemd"' | sudo tee /etc/udev/rules.d/99-zram.rules
	
        # Add /dev/zram to your fstab
        echo "/dev/zram0 none swap defaults,discard,pri=100 0 0" | sudo tee -a /etc/fstab
	
        # Optimizing swap on zram
        printf "vm.swappiness = 180\nvm.watermark_boost_factor = 0\nvm.watermark_scale_factor = 125\nvm.page-cluster = 0" | sudo tee /etc/sysctl.d/99-vm-zram-parameters.conf
    }
    fi
    
    # Installing and configuring SDDM theme
    sudo systemctl enable sddm
    sudo pacman -S qt6-svg qt6-declarative qt5-quickcontrols2 --noconfirm --needed
    sudo mkdir -pv /etc/sddm.conf.d/ /usr/share/sddm/themes/
    curl -L -O "$(curl "https://api.github.com/repos/catppuccin/sddm/releases" | jq -r '.[0].assets[42].browser_download_url')";
    7z x catppuccin-mocha-blue-sddm.zip -ocatppuccin-mocha-blue-sddm
    printf "\n\n\n\n"; sleep 3;
    sudo mv catppuccin-mocha-blue-sddm /usr/share/sddm/themes/
    sudo rm -v catppuccin-mocha-blue-sddm.zip

    if [[ $GTKENV == true ]]; then {
        # Copying Hyprland default configuration to SDDM subdirectories and exporting configuration to use SDDM native on Wayland with Hyprland
        sudo mkdir -pv /var/lib/sddm/.config/hypr/
        sudo cp -v /usr/share/hypr/hyprland.conf /var/lib/sddm/.config/hypr/hyprland.conf
        printf '%s\n' \
            '[Theme]' \
            'Current=catppuccin-mocha-blue' \
            '[General]' \
            'DisplayServer=wayland' \
            '[Wayland]' \
            'CompositorCommand=Hyprland' | sudo tee /etc/sddm.conf.d/default.conf

    } else {
        # Exporting configuration to use SDDM native on Wayland with KDE
        sudo mkdir -pv /var/lib/sddm/.config/
        #sudo cp ~/.config/kwinoutputconfig.json /var/lib/sddm/.config/ # Use these 2 commands after screen GUI configuration
        #sudo chown sddm:sddm /var/lib/sddm/.config/kwinoutputconfig.json
        printf '%s\n' \
            '[Theme]' \
            'Current=catppuccin-mocha-blue' \
            '[General]' \
            'DisplayServer=wayland' \
            'GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell' \
            '[Wayland]' \
            'CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1' | sudo tee /etc/sddm.conf.d/10-wayland.conf
    }
    fi

    printf "\n\n\n\n"

    # Change shell to ZSH
    chsh -s /usr/bin/zsh
    sudo chsh -s /usr/bin/zsh
    source $HOME/.config/zsh/.zshrc

    # Downloading Zim Framework
    curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh

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

systemTweaks "Enabling, configuring ZRAM and other tweaks"

printMessage "Please, reboot system to apply changes"


# Some useful apps and packages list:

# azote exfat-utils usbutils copyq cmus opus-tools kdeconnect dmidecode unrar timeshift ytfzf hdsentinel nwg-look wf-recorder qt5ct qt5-styleplugins waydroid distrobox android-tools lazygit qt5-wayland qt6-wayland cliphist io.github.flattool.Warehouse org.kde.kget page.codeberg.libre_menu_editor.LibreMenuEditor


# More information:

# https://wiki.archlinux.org/title/Zram
# https://gist.github.com/jwebcat/5122366
