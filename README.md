# WireGuard-RPi
This project includes a script to install and configure your WireGuard setup on a RPi.
## Getting started
**Method 1 (direct)**
```Shell
wget https://raw.githubusercontent.com/Schm1tz1/WireGuard-RPi/master/install.sh
sudo bash ./install.sh
```
*Note: ```curl -L https://raw.githubusercontent.com/Schm1tz1/WireGuard-RPi/master/install.sh | bash``` is planned, but currently not working.*

**Method 2 (includes cloning git repo)**
```Shell
git clone https://github.com/Schm1tz1/WireGuard-RPi.git
sudo bash WireGuard-RPi/install.sh
```
The following steps are straightforward - please also have a look a the first menu point "Getting started".

## Usage of WireGuard-RPi
To install WireGuard with this tool you basically need to perform 4 steps:
  1. Generate keypairs for the server and each client (Menu: ***Generate new keypair***)
  2. Generate a server config and add the server private key (Menu: ***Create new server config***)
  3. Generate a config for each client and add the server public and the client private key (Menu: ***Create new client config***)
  4. Add the clients (peers) to the server config and add their public client keys (Menu: ***Add peer to server config***)

Further steps (optional):
  - To activate WireGuard on your server on startup, a service can be installes with systemctl selecting ***Install WireGuard Service***.
  - If you want to share your client's configuration e.g. for an Andoid App you can use ***Generate QR code from client config***.
 
 ## Further Information
 - https://www.wireguard.com/install/
 - https://www.wireguard.com/quickstart/
 - https://emanuelduss.ch/2018/09/wireguard-vpn-road-warrior-setup/
 - https://github.com/adrianmihalko/raspberrypiwireguard
