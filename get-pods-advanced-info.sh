echo "Starting script..."

# Declare arrays to hold the data
declare -a namespaces
declare -a pods
declare -a ips
declare -a nodes
declare -a nodegroups

echo "Fetching nodes..."
# Gather data for all nodes
for node in $(kubectl get nodes -o name); do
    echo "Processing node: ${node#node/}"
    while IFS=$'\t' read -r namespace pod ip node_name; do
        echo "Fetching nodegroup for node: $node_name"
        nodegroup=$(kubectl get node $node_name -o=jsonpath='{.metadata.labels.eks\.amazonaws\.com/nodegroup}')
        namespaces+=("$namespace")
        pods+=("$pod")
        ips+=("$ip")
        nodes+=("$node_name")
        nodegroups+=("$nodegroup")
    done < <(kubectl get pods --all-namespaces --field-selector spec.nodeName=${node#node/} -o=jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.status.podIP}{"\t"}{.spec.nodeName}{"\n"}{end}')
done

echo "Determining maximum lengths for fields..."
# Determine the maximum length for each field
max_namespace_length=$(printf "%s\n" "${namespaces[@]}" | awk '{ if (length > max) max = length } END { print max }')
max_pod_length=$(printf "%s\n" "${pods[@]}" | awk '{ if (length > max) max = length } END { print max }')
max_ip_length=$(printf "%s\n" "${ips[@]}" | awk '{ if (length > max) max = length } END { print max }')
max_node_length=$(printf "%s\n" "${nodes[@]}" | awk '{ if (length > max) max = length } END { print max }')
max_nodegroup_length=$(printf "%s\n" "${nodegroups[@]}" | awk '{ if (length > max) max = length } END { print max }')

echo "Printing table..."
# Print the table header
printf "%-${max_namespace_length}s %-$(($max_pod_length + 2))s %-$(($max_ip_length + 2))s %-$(($max_node_length + 2))s %-$(($max_nodegroup_length + 2))s\n" "NAMESPACE" "POD" "IP" "NODE" "NODEGROUP"
echo "--------------------------------------------------------------------------------"

# Print the data
for i in "${!namespaces[@]}"; do
    printf "%-${max_namespace_length}s %-$(($max_pod_length + 2))s %-$(($max_ip_length + 2))s %-$(($max_node_length + 2))s %-$(($max_nodegroup_length + 2))s\n" "${namespaces[$i]}" "${pods[$i]}" "${ips[$i]}" "${nodes[$i]}" "${nodegroups[$i]}"
done

echo "Script completed."
