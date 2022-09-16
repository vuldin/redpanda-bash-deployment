#!/bin/bash

set -e

CLUSTER_ID="test-cluster-1"
ORGANIZATION="yourorg"
INTERNAL_HOSTS=(redpanda-internal-0.yourorg.net redpanda-internal-1.yourorg.net redpanda-internal-2.yourorg.net) # internal DNS names for each broker
EXTERNAL_HOSTS=(redpanda-external-0.yourorg.net redpanda-external-1.yourorg.net redpanda-external-2.yourorg.net) # external DNS names for each broker

# The broker ID and the array index in each HOSTS array
# If replacing a node, you will want to hard-code this value to the same node_id as the broker being replaced.
ID=`wget -q -O - http://169.254.169.254/latest/meta-data/ami-launch-index`

yum update -y

# Manages DNS resolution via no-ip, more details here: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/dynamic-dns.html
# Modify or replace this section to fit your own DNS service (Route 53, etc.)
cd ~
wget https://dmej8g5cpdyqd.cloudfront.net/downloads/noip-duc_3.0.0-beta.5.tar.gz
tar xf noip-duc_3.0.0-beta.5.tar.gz
cd noip-duc_3.0.0-beta.5
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
yum groupinstall "Development Tools" -y
/root/.cargo/bin/cargo build --release
/root/noip-duc_3.0.0-beta.5/target/release/noip-duc -g ${INTERNAL_HOSTS[$ID]} -u $NOIP_USERNAME -p $NOIP_PASSWORD --once
/root/noip-duc_3.0.0-beta.5/target/release/noip-duc -g ${EXTERNAL_HOSTS[$ID]} -u $NOIP_USERNAME -p $NOIP_PASSWORD --daemonize
# End of DNS resolution section

# Create a string of other broker names for seed_servers
IP=$(ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1)
OTHER_BROKERS=("${INTERNAL_HOSTS[@]}")
unset 'OTHER_BROKERS[$ID]'
printf -v OTHER_BROKERS_JOINED '%s,' "${OTHER_BROKERS[@]}"

# Install and configure Redpanda
curl -1sLf https://packages.vectorized.io/sMIXnoa7DK12JW4A/redpanda/cfg/setup/bash.rpm.sh | sudo -E bash
yum install -y redpanda
if [ $ID -eq 0 ]; then
  sudo -u redpanda rpk redpanda config bootstrap --id $ID --self $IP
else
  sudo -u redpanda rpk redpanda config bootstrap --id $ID --self $IP --ips ${OTHER_BROKERS_JOINED%,}
fi
sudo -u redpanda rpk redpanda config set cluster_id $CLUSTER_ID
sudo -u redpanda rpk redpanda config set organization $ORGANIZATION
sudo -u redpanda rpk redpanda config set redpanda.advertised_kafka_api "[{address: ${EXTERNAL_HOSTS[$ID]},port: 9092}]"
sudo -u redpanda rpk redpanda config set redpanda.advertised_rpc_api "{address: ${INTERNAL_HOSTS[$ID]},port: 33145}"

# Start Redpanda
systemctl restart redpanda

# Set seed_servers for the root node
if [ $ID -eq 0 ]; then
  sudo -u redpanda rpk redpanda config bootstrap --id $ID --self $IP --ips ${OTHER_BROKERS_JOINED%,}
fi
