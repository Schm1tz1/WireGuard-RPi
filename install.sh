#!/usr/bin/env bash

ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"

function getting_started() {
  echo "*******************
* Getting started *
*******************

To install WireGuard with this tool you basically need to perform 4 steps:
  1. Generate keypairs for the server and each client (Menu: 'Generate new keypair')
  2. Generate a server config and add the server private key (Menu: 'Create new server config')
  3. Generate a config for each client and add the server public and the client private key (Menu: 'Create new client config')
  4. Add the clients (peers) to the server config and add their public client keys (Menu: 'Add peer to server config')


Further steps (optional):
  - To activate WireGuard on your server on startup, a service can be installes with systemctl selecting 'Install WireGuard Service'.
  - If you want to share your client's configuration e.g. for an Andoid App you can use 'Generate QR code from client config'

"
}

function check_root() {
  if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root !" 1>&2
    exit 1
  fi
}

function prepare_config_dir() {
  if [ ! -d "/etc/wireguard" ]; then
    echo "Creating configuration directory /etc/wireguard..."
    mkdir /etc/wireguard
  fi

  cd /etc/wireguard
  umask 077
}

function prepare_system() {
  apt-get update
  apt-get upgrade
  apt-get install raspberrypi-kernel-headers
  echo "deb http://deb.debian.org/debian/ unstable main" | tee --append /etc/apt/sources.list.d/unstable.list
  apt-get install dirmngr
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8B48AD6246925553

  #TODO: check - might need those two in addition
  #apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC
  #apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138

  printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' | tee --append /etc/apt/preferences.d/limit-unstable
}

function install_packages() {
  apt-get update
  apt-get install wireguard
}

function install_service() {
  systemctl enable wg-quick@wg0
}

function readVarWithDefault() {
  read -p "$1 (default: $2): " LOCAL_VAR_FROM_USER_INPUT
  [ -z "$LOCAL_VAR_FROM_USER_INPUT" ] && LOCAL_VAR_FROM_USER_INPUT="$2"
  echo $LOCAL_VAR_FROM_USER_INPUT
}

function select_and_read_file() {
  keyfileArray=($(ls $1))

  PS3="$2: "
  select opt in "${keyfileArray[@]}"; do
    case $opt in
    $1)
      cat $opt
      break
      ;;
    *) echo "invalid option $REPLY" ;;
    esac
  done
}

function generate_config_server() {

  SRV_IP_RANGE=$(readVarWithDefault "Local VPN Server IP and Mask" "10.10.10.1/24")
  echo " -> $SRV_IP_RANGE"
  echo

  SRV_PORT=$(readVarWithDefault "Port for WireGuard VPN" "51820")
  echo " -> $SRV_PORT"
  echo

  SRV_PRIVKEY=$(select_and_read_file "/etc/wireguard/*.key" "Select server private key")
  echo " -> private key added (hidden)"
  echo

  echo "[Interface]
Address = $SRV_IP_RANGE
ListenPort = $SRV_PORT
PrivateKey = $SRV_PRIVKEY

# enable IP forwarding just in case this config is not set by default
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = sysctl -w net.ipv6.conf.all.forwarding=1

# set forwarding policies in iptables
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
" >wg0.conf && echo "New server config for wg0 created!"

}

function add_peer_server() {

  CLIENT_NAME="client-$(readVarWithDefault "Enter client name" "smartphone")"
  echo " -> $CLIENT_NAME"
  echo

  CLIENT_IP=$(readVarWithDefault "Client IP range (e.g. single client 10.10.10.2/32, vpn/remote network 10.10.10.0/24, route all traffic 0.0.0.0/0...) " "10.10.10.2/32")
  echo " -> $CLIENT_IP"
  echo

  CLIENT_PUBKEY=$(select_and_read_file "/etc/wireguard/*.key" "Select client public key")
  echo " -> $CLIENT_PUBKEY"
  echo
  echo "# Client $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUBKEY
AllowedIPs = $CLIENT_IP
" >>wg0.conf && echo "New peer $CLIENT_IP added to config for wg0!"
}

function generate_config_client() {

  CLIENT_NAME="client-$(readVarWithDefault "Enter client name (will be prefixed with client-)" "smartphone")"
  echo " -> $CLIENT_NAME"
  echo

  SRV_URL=$(readVarWithDefault "Public Server URL/IP" "10.10.10.1")
  echo " -> $SRV_URL"
  echo

  SRV_PORT=$(readVarWithDefault "Public Server Port" "51820")
  echo " -> $SRV_PORT"
  echo

  SRV_PUBKEY=$(select_and_read_file "/etc/wireguard/*.key" "Select server public key")
  echo " -> $SRV_PUBKEY"

  CLIENT_IP=$(readVarWithDefault "Client IP" "10.10.10.2")
  echo " -> $CLIENT_IP"
  echo

  CLIENT_PRIVKEY=$(select_and_read_file "/etc/wireguard/*.key" "Select client private key")
  echo " -> private key added (hidden)"
  echo

  DNS_SERVER=$(readVarWithDefault "DNS Server" "192.168.0.1")
  echo " -> $DNS_SERVER"
  echo

  echo "[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = $CLIENT_IP
DNS = $DNS_SERVER

[Peer]
PublicKey = $SRV_PUBKEY
Endpoint = $SRV_URL:$SRV_PORT
AllowedIPs = 0.0.0.0/0 # and/or local netmask, e.g. 192.168.178.0/24
PersistentKeepalive = 25
" >$CLIENT_NAME.conf

}

function generateNewKeypair() {
  KEY_NAME=$(readVarWithDefault "Name of keypair" "newKey")
  wg genkey | tee $KEY_NAME-private.key | wg pubkey >$KEY_NAME-public.key
}

function show_menu() {
  echo " __          ___           _____                     _        _____  _____ _ "
  echo " \ \        / (_)         / ____|                   | |      |  __ \|  __ (_)"
  echo "  \ \  /\  / / _ _ __ ___| |  __ _   _  __ _ _ __ __| |______| |__) | |__) | "
  echo "   \ \/  \/ / | | '__/ _ \ | |_ | | | |/ _\` | '__/ _\` |______|  _  /|  ___/ |"
  echo "    \  /\  /  | | | |  __/ |__| | |_| | (_| | | | (_| |      | | \ \| |   | |"
  echo "     \/  \/   |_|_|  \___|\_____|\__,_|\__,_|_|  \__,_|      |_|  \_\_|   |_|"
  echo "                                                                             "

  PS3='Please enter your choice: '
  options=("Getting started" "List all configs and keys" "Display specific config" "Generate new keypair" "Create new server config" "Add peer to server config" "Create new client config" "Generate QR code from client config" "Install WireGuard Service" "Quit")
  select opt in "${options[@]}"; do
    case $opt in
    "Getting started")
      getting_started
      ;;
    "List all configs and keys")
      echo "*** Configs ***"
      ls -l /etc/wireguard/*.conf
      echo
      echo "*** Keys ***"
      ls -l /etc/wireguard/*.key
      ;;
    "Display specific config")
      select_and_read_file "/etc/wireguard/*.conf" "Select configuration file"
      ;;
    "Generate new keypair")
      generateNewKeypair
      ;;
    "Create new server config")
      generate_config_server
      ;;
    "Add peer to server config")
      add_peer_server
      ;;
    "Create new client config")
      generate_config_client
      ;;
    "Generate QR code from client config")
      select_and_read_file "/etc/wireguard/*.conf" "Select client configuration" | qrencode -t ansiutf8
      ;;
    "Install WireGuard Service")
      install_service
      ;;
    "Quit")
      echo "*************************************"
      echo "** So long and thanks for the fish **"
      echo "*************************************"
      exit 0
      ;;
    *) echo "invalid option $REPLY" ;;
    esac
  done
}

function main() {
  check_root
  prepare_config_dir

  # infinite menu loop
  while :; do
    show_menu
  done

  exit
}

main
