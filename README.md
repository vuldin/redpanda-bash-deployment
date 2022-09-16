# Redpanda user data shell script

This script is meant to be passed as user data to newly launched Amazon Linux 2 AMI instances on AWS EC2. More details on this process can be found here:

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html

This will deploy a Redpanda node as part of a cluster based on the given hosts, and is meant to show how `node_id` and `seed_servers` can be properly configured during initial deployment of the node (whether the node is part of a new or existing cluster).

This is not ready for production use. There are a number of additional parameters you would want to set for Redpanda to be ran in anything but a test deployment.

## Environment variables

The following environment variables are found at the top of the script:

- `CLUSTER_ID`: The cluster ID (could be department/team name, for example)
- `ORGANIZATION`: The organization name
- `INTERNAL_HOSTS`: The broker IPs or hostnames, used for internal advertised listeners and communication between brokers (must be resolvable by each broker)
- `EXTERNAL_HOSTS`: The IPs or hostnames that will be advertised to external clients (must be resolvable by each client)

## Note on DNS resolution

For this example I used [no-ip](https://www.noip.com/), and two additional environment variables related to this section: `NOIP_USERNAME` and `NOIP_PASSWORD`. You will need to set these variables if you plan to use the no-ip section of this example.

Setting username/password variables in code is insecure. Instead you could use [AWS Systems Manager Parameter Store](https://us-east-1.console.aws.amazon.com/systems-manager/parameters?region=us-east-1) to store these variables and retrieve the values from within this user data script.

## Steps

Copy this script into the user data field in the Advanced details section of the launch instance wizard for EC2. More details can be found here:

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html?icmpid=docs_ec2_console#user-data-console

Once your instances have started, you can monitor the progress of the user data script with the following command:

```bash
sudo tail -f /var/log/cloud-init-output.log
```

As-is, the script takes 2-4 minutes to complete. Most of this is due to the rust install and compilation steps in the no-ip package, so removing or replacing this section will greatly speed up startup times.