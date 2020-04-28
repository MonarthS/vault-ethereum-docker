FROM ubuntu:18.04

RUN apt-get update -y && \
    apt-get install -y jq

RUN  apt-get update \
  && apt-get install -y wget \
  && apt-get install -y libssl-dev \
  && apt-get install -y unzip

ADD run_vault.sh /usr/local/bin/run_vault
RUN chmod +x /usr/local/bin/run_vault

ADD unseal_vault.sh /usr/local/bin/unseal_vault
RUN chmod +x /usr/local/bin/unseal_vault

ADD initialize_vault.sh /usr/local/bin/initialize_vault
RUN chmod +x /usr/local/bin/initialize_vault

ADD install_vault.sh ./
RUN chmod +x install_vault.sh
RUN ./install_vault.sh --linux

EXPOSE 8200
CMD ["vault", "server", "-config", "/etc/vault.d/vault.hcl"]