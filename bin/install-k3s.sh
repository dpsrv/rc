#!/bin/bash -ex

[ $(id -u) -eq 0 ] || exec sudo $0 $@

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--disable traefik' sh -s - --docker

[ -f /etc/rancher/k3s/config.yaml ] || cat > /etc/rancher/k3s/config.yaml << _EOT_
write-kubeconfig-mode: "0644"
cluster-init: true
_EOT_

[ -f /etc/profile.d/k3s.sh ] || cat > /etc/profile.d/k3s.sh << _EOT_
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
_EOT_

chgrp docker /usr/local/bin/k3s /etc/rancher/k3s/k3s.yaml /etc/rancher/k3s/config.yaml
chmod g+s /usr/local/bin/k3s
chmod g+rw /etc/rancher/k3s/k3s.yaml


