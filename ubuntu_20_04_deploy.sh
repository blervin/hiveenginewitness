#!/bin/bash
###################
## SET VARIABLES ##
###################
SERVER_NAME="witness"
GIT_REPO="https://github.com/hive-engine/steemsmartcontracts.git"
GIT_TAG=he_v1.2.0

##################
## INIT UPDATES ##
##################
apt-get update -y
apt-get upgrade -y

####################
## INSTALL BASICS ##
####################
apt install git -y
apt-get -y install npm
apt install ufw -y

################
## CLONE REPO ##
################
mkdir -p /var/$SERVER_NAME
cd /var/$SERVER_NAME
git clone --recursive --branch $GIT_TAG $GIT_REPO ./
# git checkout heRelease1.1

######################
## INSTALL FAIL2BAN ##
######################
apt-get -y install fail2ban
touch /etc/fail2ban/jail.local
echo "[DEFAULT]" >> /etc/fail2ban/jail.local
echo "bantime = 3600" >> /etc/fail2ban/jail.local
echo "banaction = iptables-multiport" >> /etc/fail2ban/jail.local
echo "ignoreip = 127.0.0.1/8" >> /etc/fail2ban/jail.local
echo "[sshd]" >> /etc/fail2ban/jail.local
echo "enabled = true" >> /etc/fail2ban/jail.local
systemctl start fail2ban
systemctl enable fail2ban

#####################
## INSTALL MONGODB ##
#####################
cd /var/$SERVER_NAME
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
apt-get update -y
apt-get -y -o Dpkg::Options::="--force-confold" install mongodb-org
sed -i '/replication/a \ \ \ replSetName: "rs0"' /etc/mongod.conf
sed -i 's/#replication/replication/g' /etc/mongod.conf
systemctl stop mongod
systemctl start mongod

################
## RESTORE DB ##
################
cd /var/$SERVER_NAME
# wget http://api2.hive-engine.com/hsc_20210203_b50993579.archive
# mongo --eval "rs.initiate()"
# mongorestore --gzip --archive=hsc_20210203_b50993579.archive

##############
## SET SWAP ##
##############
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

##################
## INSTALL NODE ##
##################
curl -sL https://deb.nodesource.com/setup_14.x | -E bash -
apt-get install -y nodejs
apt-get -y install npm

#################
## FINAL SETUP ##
#################
cd /var/$SERVER_NAME
npm install dotenv
npm i
npm i -g pm2
sed -i 's/"startHiveBlock": 41967000/"startHiveBlock": 0/g' config.json
sed -i 's/"witnessEnabled": false/"witnessEnabled": true/g' config.json
ufw allow 5001

#####################
## SET WITNESS KEY ##
#####################
cat > /var/$SERVER_NAME/.env << EOF
ACTIVE_SIGNING_KEY=5K...
ACCOUNT=youraccount
EOF