#!/bin/bash

# Custom repositories
CUSTOM_REPOSITORIES=("ppa:pi-rho/dev")

# Dependences Packs
DEPENDENCES_PACKS=("curl" "git")

# Packages to install
DEB_PACKS=( "apt-transport-https" "ca-certificates" "software-properties-common"
            "dconf-cli" "silversearcher-ag" "vim-gnome")

# Custom apps to Install (without package management or custom configs)
CUSTOM_APPS=("install_solarized")

# List of files to link
FILES_LINK=("aliases" "aliases.local" "vimrc" "zsh"
"bin" "vim" "git/*")

# Dotfiles folder name
DOT_FOLDER='dotfiles'

# ---------------------------------------
# Custom install functions
# ---------------------------------------

function install_solarized(){
  mkdir -p "$HOME/.$DOT_FOLDER"
  git clone https://github.com/Anthony25/gnome-terminal-colors-solarized.git "$HOME/.$DOT_FOLDER/gnome-terminal-colors-solarized"
  "$HOME/.$DOT_FOLDER/gnome-terminal-colors-solarized/install.sh"
}

# ------------ End of custom install functions

function check_previus_install(){
  if [ -d "$HOME/.$DOT_FOLDER" ];then
    return 0
  else
    return 1
  fi
}

function install_dependences(){
  echo -e '\n\n ... install dependences packs'
  for pkg in "${DEPENDENCES_PACKS[@]}"; do
    sudo apt-get install -y $pkg
  done
}

function install_pkgs(){

  echo -e '\n\n ... install custom prerequisities'
  for install_custom in "${CUSTOM_DEPENDENCES[@]}"; do
    $install_custom
  done

  echo -e '\n\n ... add custom reositories'
  for repo in "${CUSTOM_REPOSITORIES[@]}"; do
    sudo add-apt-repository -y $repo
  done

  sudo apt-get update

  echo -e '\n\n ... install commons packs'
  for pkg in "${DEB_PACKS[@]}"; do
    sudo apt-get install -y $pkg
  done

  echo -e '\n\n ... install custom apps'
  for install_custom in "${CUSTOM_APPS[@]}"; do
    $install_custom
  done
}

function clone_repository(){
  git clone https://github.com/DougBR/ws_dotfiles.git "$HOME/.$DOT_FOLDER"
}

function backup_file(){
  if [ -e "$HOME/.$1" ];then
    echo "Making a backup of the file: $1"
    mv "$HOME/.$1" "$HOME/ws_bkp.$1"
  fi
}

function create_symbol_link(){
  echo "Create symbol link to $1 -> $2"
  ln -nfs "$1" "$2"
}

function create_files_link(){
  for file in "${FILES_LINK[@]}"; do

    file_source="$HOME/.$DOT_FOLDER/$file"
    file_link="$HOME/.$file"

    if [ "${file_source: -1}" = "*" ];then
      for lfile in $file_source;do
        lfile_name=`xargs -n 1 basename <<< $lfile`
        backup_file $lfile_name
        create_symbol_link $lfile "$HOME/.$lfile_name"
      done
    else
      backup_file $file
      create_symbol_link $file_source $file_link
    fi
  done
}

function install_fonts(){
  mkdir -p "$HOME/.fonts" && cp "$HOME/.$DOT_FOLDER/fonts/"* "$HOME/.fonts" && fc-cache -vf "$HOME/.fonts"
}

function install_vim_plugins(){
  vim -N "+set hidden" "+syntax on" +PlugInstall +qall
}

function already_installed(){
  echo
  echo 'Dotfiles is already installed!'
  echo
  echo 'To reinstall:'
  echo " $0 --reinstall"
}

function set_final_config(){
  profile=$(gsettings get org.gnome.Terminal.ProfilesList default)
  profile=${profile:1:-1}
  gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/" login-shell true
}

function install_dotfiles(){
  if check_previus_install; then
    already_installed
    exit 1
  fi

  echo -e ' \n\n---- Now it´ll install dependencies'
  install_dependences

  echo -e ' \n\n---- Now it´ll clone Git repository'
  clone_repository

  echo -e ' \n\n---- It´ll install the packages'
  install_pkgs

  echo -e ' \n\n---- It´ll create symbol links to files'
  create_files_link

  echo -e ' \n\n---- It´ll install patched fonts for PowerLine/Lightline'
  install_fonts

  echo -e ' \n\n---- It´ll install vim plugins'
  install_vim_plugins
  
  echo -e ' \n\n---- It´ll make the last configs'
  set_final_config
}

function script_help(){
  echo
  echo "Uso: $0 OPTIONS"
  echo
  echo 'Options:'
  echo ' -i, --install       Install WS Dotfiles.'
  echo ' -r, --reinstall     Reinstall WS Dotfiles.'
  echo
  echo ' INSTALL SPECIFIC ITEMS'
  echo 'fzf:      --install-fzf'
}

case "$1" in

  --install|-i)
    install_dotfiles
    ;;

  --reinstall|-r)
    if check_previus_install; then
      sudo rm -rf "$HOME/.$DOT_FOLDER"
      sudo rm -rf "$HOME/.zsh-syntax-highlighting"
    fi

    install_dotfiles
    ;;

  --test)
    ;;

  --install-fzf)
    install_fzf
    ;;
  *)
    script_help
    ;;
esac
