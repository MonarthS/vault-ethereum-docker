# vault-ethereum non-cert

#### Build Docker Image
```
docker build --tag vault-test:2.0 .
```

#### Run It
```
docker-compose up -d
```

#### Initialize Vault
```
docker exec vault-eth-test unseal_vault
```
