#!/bin/bash

set -e

CLUSTER_ID="test-cluster-1"
ORGANIZATION="org-name"
PLATFORM="ubuntu"
# a note on HOSTS and BROKERS arrays below:
# must be same-length arrays and ordered so host matches broker in their respective arrays
HOSTS=(ec2-35-90-229-89.us-west-2.compute.amazonaws.com ec2-54-200-65-43.us-west-2.compute.amazonaws.com ec2-54-203-79-72.us-west-2.compute.amazonaws.com)
BROKERS=(172.31.11.97 172.31.12.225 172.31.0.200)

for i in ${!HOSTS[@]}; do
  HOST=${HOSTS[$i]}
  OTHER_BROKERS=("${BROKERS[@]}")
  unset 'OTHER_BROKERS[$i]'
  printf -v OTHER_BROKERS_JOINED '%s,' "${OTHER_BROKERS[@]}"
  if [ $PLATFORM == "ubuntu" ]; then
    ssh ubuntu@$HOST 'curl -1sLf https://packages.vectorized.io/sMIXnoa7DK12JW4A/redpanda/cfg/setup/bash.deb.sh | sudo -E bash'
    ssh ubuntu@$HOST 'sudo apt update'
    ssh ubuntu@$HOST 'sudo apt install redpanda'
    #ssh ubuntu@$HOST 'sudo rpk redpanda mode production'
    #ssh ubuntu@$HOST 'sudo rpk tune all'
    #ssh ubuntu@$HOST 'systemctl restart redpanda-tuner'
    if [ $i -eq 0 ]; then
      ssh ubuntu@$HOST "sudo -u redpanda rpk redpanda config bootstrap --id $i --self ${BROKERS[$i]}"
    else
      ssh ubuntu@$HOST "sudo -u redpanda rpk redpanda config bootstrap --id $i --self ${BROKERS[$i]} --ips ${OTHER_BROKERS_JOINED%,}"
    fi
    ssh ubuntu@$HOST "sudo -u redpanda rpk redpanda config set cluster_id $CLUSTER_ID"
    ssh ubuntu@$HOST "sudo -u redpanda rpk redpanda config set organization $ORGANIZATION"
    ssh ubuntu@$HOST "sudo -u redpanda rpk redpanda config set redpanda.advertised_kafka_api '{
  address: ${BROKERS[$i]},
  port: 9092
}' --format yaml"
    ssh ubuntu@$HOST "sudo -u redpanda rpk redpanda config set redpanda.advertised_rpc_api '{
  address: ${BROKERS[$i]},
  port: 33145
}' --format yaml"
    ssh ubuntu@$HOST 'sudo systemctl restart redpanda'
    ssh ubuntu@$HOST "sudo -u redpanda rpk redpanda config bootstrap --id $i --self ${BROKERS[$i]} --ips ${OTHER_BROKERS_JOINED%,}"
  fi
done
