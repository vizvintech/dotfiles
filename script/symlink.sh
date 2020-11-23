#!/usr/bin/env bash
### ---------------- Symlink dotfiles into home directory ----------------- ###
# Run by strap-after-setup

symlink_dir_contents() {
  TARGET_DIR=$3/${1##$2/}
  ! [ -d "$TARGET_DIR" ] && mkdir -p "$TARGET_DIR"
  for FILE in "$1/"*; do
    symlink_file "$FILE" "$2" "$3"
  done
}

symlink_file() {
  ln -fns "$1" "$3/${1##$2/}"
}

symlink_repo_dotfiles() {
  echo "-> Symlinking dotfiles into home directory."
  DOT_DIR=$HOME/.dotfiles
  IGNORES=("$DOT_DIR/.git" "$DOT_DIR/.github" "$DOT_DIR/.gitignore")
  for DOTFILE in "$DOT_DIR/."*; do
    if ! [[ ${IGNORES[*]} =~ $DOTFILE ]]; then
      [ -d "$DOTFILE" ] && symlink_dir_contents "$DOTFILE" "$DOT_DIR" "$HOME"
      [ -f "$DOTFILE" ] && symlink_file "$DOTFILE" "$DOT_DIR" "$HOME"
    fi
  done
}

symlink_vscodium_settings() {
  echo "-> Symlinking VSCodium settings."
  SETTINGS_DIR=$HOME/.dotfiles/codium
  case $(uname -s) in
  Darwin)
    declare -a DIRS=(
      "$HOME/Library/Application Support/Code"
      "$HOME/Library/Application Support/Code - Insiders"
      "$HOME/Library/Application Support/VSCodium"
    )
    ;;
  Linux)
    declare -a DIRS=(
      "$HOME/.config/Code"
      "$HOME/.config/Code - Insiders"
      "$HOME/.config/VSCodium"
    )
    ;;
  esac
  for DIR in "${DIRS[@]}"; do
    symlink_dir_contents "$SETTINGS_DIR/User" "$SETTINGS_DIR" "$DIR"
  done
}

if symlink_repo_dotfiles && symlink_vscodium_settings; then
  echo "-> Symlinking successful. Finishing up..."
  chmod 700 "$HOME"/.gnupg
  chmod 600 "$HOME"/.gnupg/gpg.conf
  # https://pqrs.org/osx/karabiner/document.html#configuration-file-path
  # Restart Karabiner after symlinking config
  KARABINER=gui/"$(id -u)"/org.pqrs.karabiner.karabiner_console_user_server
  if launchctl kickstart "$KARABINER" >/dev/null 2>&1; then
    launchctl kickstart -k "$KARABINER"
  else
    echo "-> Skipping Karabiner restart."
  fi
  echo "-> Finished."
else
  echo "-> Symlinking unsuccessful."
  ! [ -d "$HOME"/.dotfiles ] && echo "-> Error: Dotfiles directory not found."
fi
