#!/bin/bash

PLUGIN_VERSION="0.2.12"
VAULT_VERSION="1.0.3"

function print_help {
    echo "Usage: bash install.sh OPTIONS"
    echo -e "\nOPTIONS:"
    echo -e "  --linux\tInstall Linux version"
    echo -e "  --darwin\tInstall Darwin (MacOS) version"
    echo -e "\nSee README.md for dependencies"
}

function gencerts {

  openssl req -subj '/O=My Company Name LTD./C=US/CN=localhost' -new -newkey  rsa:4096 -sha256 -days 3650 -x509 -nodes -keyout root.key -out root.crt
  openssl req -subj '/O=My Company Name LTD./C=US/CN=localhost' -new -newkey rsa:4096 -sha256 -nodes -out vault.csr -keyout vault.key
  echo 000a > serialfile
  touch certindex

cat << EOF > ./vault.cnf
[ ca ]
default_ca = myca

[ myca ]
new_certs_dir = .
unique_subject = no
certificate = ./root.crt
database = ./certindex
private_key = ./root.key
serial = ./serialfile
default_days = 365
default_md = sha256
policy = myca_policy
x509_extensions = myca_extensions
copy_extensions = copy

[ myca_policy ]
commonName = supplied
stateOrProvinceName = optional
countryName = supplied
emailAddress = optional
organizationName = supplied
organizationalUnitName = optional

[ myca_extensions ]
basicConstraints = CA:false
subjectKeyIdentifier = hash
subjectAltName = @alt_names
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = localhost
IP.1 = 0.0.0.0
EOF

  openssl ca -batch -config vault.cnf -notext -in vault.csr -out vault.crt
  mv *.crt /etc/vault.d
  mv *.key /etc/vault.d
  rm certindex
  rm serialfile
  rm serialfile.*
  rm vault.cnf
  rm vault.csr
  rm *.pem
  rm certindex.*

}


function grab_hashitool {
  echo "Tool: $1"
  echo "Version: $2"
  echo "OS: $3"


  wget -O ./$1.zip https://releases.hashicorp.com/$1/$2/$1_$2_$3_amd64.zip
  unzip ./$1.zip
  if [ $3 == "linux" ] ; then
    mv ./$1 /usr/local/bin/$1
  else
    mv ./$1 /usr/local/bin/$1
  fi
  rm ./$1.zip
}


function grab_plugin {
  echo "OS: $1"
  echo "Version: $2"

  wget -O ./$1.zip https://github.com/immutability-io/vault-ethereum/releases/download/v$2/vault-ethereum_$2_$1_amd64.zip
}

function move_plugin {
  echo "OS: $1"
  unzip ./$1.zip
  rm ./$1.zip
  mv ./vault-ethereum /etc/vault.d/vault_plugins/vault-ethereum
}

if [ -n "`$SHELL -c 'echo $ZSH_VERSION'`" ]; then
    # assume Zsh
    shell_profile="zshrc"
elif [ -n "`$SHELL -c 'echo $BASH_VERSION'`" ]; then
    # assume Bash
    shell_profile="bashrc"
fi

if [ "$1" == "--darwin" ]; then
    PLUGIN_OS="darwin"
elif [ "$1" == "--linux" ]; then
    PLUGIN_OS="linux"
elif [ "$1" == "--help" ]; then
    print_help
    exit 0
else
    print_help
    exit 1
fi

if [ -d "/etc/vault.d" ]; then
    echo "The 'etc/vault.d' directories already exist. Exiting."
    exit 1
fi

mkdir -p /etc/vault.d/vault_plugins
mkdir -p /etc/vault.d/data

gencerts

grab_plugin $PLUGIN_OS $PLUGIN_VERSION
move_plugin $PLUGIN_OS
grab_hashitool vault $VAULT_VERSION $PLUGIN_OS

cat << EOF > /etc/vault.d/vault.hcl
"default_lease_ttl" = "24h"
"disable_mlock" = "true"
"max_lease_ttl" = "24h"

"backend" "file" {
  "path" = "/etc/vault.d/data"
}

"api_addr" = "https://127.0.0.1:8200"

"listener" "tcp" {
  "address" = "0.0.0.0:8200"

  "tls_cert_file" = "/etc/vault.d/vault.crt"
  "tls_client_ca_file" = "/etc/vault.d/root.crt"
  "tls_key_file" = "/etc/vault.d/vault.key"
}

"plugin_directory" = "/etc/vault.d/vault_plugins"
EOF
