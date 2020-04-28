#!/bin/bash

function _unseal_vault {
  for (( COUNTER=0; COUNTER<5; COUNTER++ ))
  do
    key=$(cat /_private/UNSEAL_$COUNTER.txt)
    vault operator unseal $key
  done
}

if [ ! -f /_private/UNSEAL_0.txt ]; then
  echo "File not found! initializing..."
  initialize_vault
  exit 2
fi

# unseal the vault
_unseal_vault