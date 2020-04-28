#!/bin/bash

function initialize {
  export VAULT_ADDR=http://localhost:8200
  export VAULT_INIT=$(vault operator init -format=json)
  if [[ $? -eq 2 ]] ; then
    echo "Vault initialization failed!"
    exit 2
  fi
  export VAULT_TOKEN=$(echo $VAULT_INIT | jq .root_token | tr -d '"')
  mkdir /_private
  echo "$VAULT_TOKEN" >> /_private/VAULT_TOKEN.txt
  for (( COUNTER=0; COUNTER<5; COUNTER++ ))
  do
    key=$(echo $VAULT_INIT | jq '.unseal_keys_hex['"$COUNTER"']' | tr -d '"')
    vault operator unseal $key
    echo "$key" >> "/_private/UNSEAL_$COUNTER.txt"
  done
  unset VAULT_INIT
}

function install_plugin {
  vault write sys/plugins/catalog/ethereum-plugin \
        sha_256="$(cat /SHA256SUM)" \
        command="vault-ethereum"

  if [[ $? -eq 2 ]] ; then
    echo "Vault Catalog update failed!"
    exit 2
  fi

  vault secrets enable -path=ethereum -plugin-name=ethereum-plugin plugin
  if [[ $? -eq 2 ]] ; then
    echo "Failed to mount Ethereum plugin!"
    exit 2
  fi
  rm /SHA256SUM
}

initialize
install_plugin