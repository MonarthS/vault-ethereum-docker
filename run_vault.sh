nohup /usr/local/bin/vault server -config /etc/vault.d/vault.hcl &> /dev/null &
sleep 10
unseal_vault