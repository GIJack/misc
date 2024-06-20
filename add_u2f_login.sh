#!/usr/bin/env bash

# from here https://wiki.archlinux.org/title/Universal_2nd_Factor#Adding_a_key

### CONFIG

### /CONFIG

main() {
  echo "Touch YubiKey Button..."
  mkdir -p ~/.config/Yubico
  pamu2fcfg -o pam://${HOSTNAME} -i pam://${HOSTNAME} > ~/.config/Yubico/u2f_keys
}

main "${@}"
