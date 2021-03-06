#!/bin/sh
#wait until another process are trying updating the system
while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 1; done

sudo ufw allow 80
sudo ufw allow 443

DEBIAN_FRONTEND=noninteractive  sudo apt-get update
DEBIAN_FRONTEND=noninteractive  sudo apt-get install -y npm
npm install pm2@latest -g

echo "{{priv_key}}" >> $HOME/.ssh/id_rsa
echo "{{pub_key}}" >> $HOME/.ssh/id_rsa.pub
chmod  400 ~/.ssh/id_rsa

ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts

mkdir /root/.deployed
mv /root/cluster_config.json /root/.deployed/config.json

while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done

DEBIAN_FRONTEND=noninteractive sudo apt-get -y update
DEBIAN_FRONTEND=noninteractive sudo apt-get install curl wget gnupg2 -y
. /etc/os-release
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
sudo wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key
sudo apt-key add Release.key
DEBIAN_FRONTEND=noninteractive sudo apt-get update -qq -y
DEBIAN_FRONTEND=noninteractive sudo apt-get -qq --yes install podman

while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done

DEBIAN_FRONTEND=noninteractive sudo apt-get install -y haproxy
mkdir /etc/haproxy/certs
rm /etc/haproxy/haproxy.cfg
mv /root/haproxy.cfg /etc/haproxy/haproxy.cfg
sudo systemctl restart haproxy

git clone {{client_URL}}
cd dep-cluster
npm cache clean --force
npm install
pm2 start index.js --name "dep-cluster"

while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done


#DEBIAN_FRONTEND=noninteractive apt-get install -y snapd
#sudo snap install --classic certbot
#sudo ln -s /snap/bin/certbot /usr/bin/certbot

#certbot certonly --non-interactive --agree-tos -m dev@{{domain}} --webroot -w /root/dep-cluster/certs -d {{cluster_id}}.{{domain}}
#DOMAIN='{{cluster_id}}.{{domain}}' sudo -E bash -c 'cat /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem > /etc/haproxy/certs/$DOMAIN.pem'

#rm /etc/haproxy/haproxy.cfg
#mv /root/haproxy-ssl.cfg /etc/haproxy/haproxy.cfg
#sudo systemctl restart haproxy
