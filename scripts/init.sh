kops create cluster \
    --name=${CLUSTER_FULL_NAME} \
    --zones=${ZONES} \
    --master-size="t2.medium" \
    --node-size="t2.medium" \
    --node-count=${nodecount} \
    --dns-zone=${DOMAIN_NAME} \
    --ssh-public-key="k8sintelycore.pub"


kops update cluster --name "$CLUSTER_FULL_NAME" --yes
