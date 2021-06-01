#!/bin/bash
###################
## SET VARIABLES ##
###################
SERVER_NAME="witness"
GIT_REPO="https://github.com/hive-engine/steemsmartcontracts.git"
GIT_TAG=he_v1.4.0

##################
## INIT UPDATES ##
##################
apt-get update \
  -o Dpkg::Options::=--force-confold \
  -o Dpkg::Options::=--force-confdef \
  -y --allow-downgrades --allow-remove-essential --allow-change-held-packages

####################
## INSTALL BASICS ##
####################
apt install git -y
apt install ufw -y

################
## CLONE REPO ##
################
mkdir -p /var/$SERVER_NAME
cd /var/$SERVER_NAME
git clone --recursive --branch $GIT_TAG $GIT_REPO ./

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
mongo --eval "rs.initiate()"

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
curl -sL https://deb.nodesource.com/setup_15.x | bash -
apt-get install -y nodejs
apt-get -y install npm

#################
## FINAL SETUP ##
#################
cd /var/$SERVER_NAME
npm install dotenv
npm i
npm i -g pm2
sed -i 's/"startHiveBlock": 41967000/"startHiveBlock": 54107973/g' config.json
sed -i 's/"witnessEnabled": false/"witnessEnabled": true/g' config.json
ufw allow 5001

#####################
## SET WITNESS KEY ##
#####################
cat > /var/$SERVER_NAME/.env << EOF
ACTIVE_SIGNING_KEY=5K...
ACCOUNT=youraccount
EOF

################
## RESTORE DB ##
################
mongo --eval "rs.initiate()"
systemctl restart mongod
cd /var/$SERVER_NAME
wget https://cdn.rishipanthee.com/hiveengine/hsc_live.archive
systemctl restart mongod
mongorestore --gzip --archive=hsc_live.archive