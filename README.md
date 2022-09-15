# Redpanda bash deployment

This script will deploy a number of Redpanda nodes in a cluster based on the given hosts. This script is meant to show how `node_id` and `seed_servers` can be properly configured during initiall deployment.

This is not ready for production use. There are a number of additional parameters that you would want to set for anything but a test deployment.

## Environment variables

The following environment variables are found at the top of the script:

- `CLUSTER_ID`: The cluster ID (could be department/team name, for example)
- `ORGANIZATION`: The organization name
- `PLATFORM`: The platform name, valid choices are `ubuntu` and `redhat`
- `HOSTS`: The hosts where Redpanda will be deployed. This could be used for external advertised listeners if security groups allow (based on your environment)
- `BROKERS`: The broker IPs or hostnames, used for internal advertised listeners and communication between brokers (must be resolvable by each broker if using hostnames)

## Steps

```
git clone https://github.com/vuldin/redpanda-bash-deployment.git
# edit variables according to your environment
chmod +x index.sh
./index.sh
```
