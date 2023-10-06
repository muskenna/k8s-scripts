#!/bin/bash

# Fetch node information in JSON format
node_info=$(kubectl get nodes -o json)
context=$(kubectl config current-context)

# Function to get subnet ID from EC2 instance ID
get_subnet_id() {
    local instance_id="$1"
    aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[].Instances[].SubnetId" --output text --profile cicd-dev --region us-west-2
}

# Header
printf "%-45s %-20s %-25s %-50s %-10s\n" "Node Name" "Instance ID" "Subnet ID" "Node Group" "Env"
echo "--------------------------------------------------------------------------------------------------------------------------------------------------------------------"

# Parse the node information to generate a table of instance IDs, their corresponding subnet IDs, and node groups
echo "$node_info" | jq -r '.items[] | "\(.metadata.name)\t\(.metadata.annotations["csi.volume.kubernetes.io/nodeid"])\t\(.metadata.labels["eks.amazonaws.com/nodegroup"])"' | while read -r node instance_id_json nodegroup; do
    instance_id=$(echo "$instance_id_json" | jq -r '.["ebs.csi.aws.com"]')
    subnet_id=$(get_subnet_id "$instance_id")
    printf "%-45s %-20s %-25s %-50s %-10s\n" "$node" "$instance_id" "$subnet_id" "$nodegroup" "$context"
done
