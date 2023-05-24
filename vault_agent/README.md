# preparations
get docker, minikube, helm, kubectl

# clone that repo and build the image in it
git clone https://github.com/raakatz/vault-mongodb.git

# run the mongo DB
docker run -d \
    -p 0.0.0.0:27017:27017 -p 0.0.0.0:28017:28017 \
    --name=mongodb \
    -e MONGO_INITDB_ROOT_USERNAME="mdbadmin" \
    -e MONGO_INITDB_ROOT_PASSWORD="hQ97T9JJKZoqnFn2NXE" \
    mongo

kubectl run   --port 27017 --port 28017     --image=yuvalammatrix/mongo:latest     --env=MONGO_INITDB_ROOT_USERNAME="mdbadmin" --env=MONGO_INITD
B_ROOT_PASSWORD="hQ97T9JJKZoqnFn2NXE"     mongo

kubectl create secret docker-registry dockerhub --docker-username=yuvalammatrix --docker-password=Iamstillmyself5% --docker-email=yuvalam@matrix.co.il

# start the minikube
minikube start

# get, update and install this helm chart
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault --set "server.dev.enabled=true"

# now you have the vault dev server and vault-agent-injector, check they are running
kubectl get pods


## create your secret in vault
# enter the container vault-0
kubectl exec -it vault-0 -- /bin/sh


# vault secrets enable database
vault write database/config/my-mongodb-database \
    plugin_name=mongodb-database-plugin \
    allowed_roles="my-role" \
    connection_url="mongodb://{{username}}:{{password}}@127.0.0.1:27017/admin?tls=false" \
    username="mdbadmin" \
    password="hQ97T9JJKZoqnFn2NXE"


# secret creation
vault secrets enable -path=internal kv-v2 
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"

# now you can check you secret exist
vault kv get internal/database/config

## configure kubernetes authentication
# still inside the contianer of vault-0 enable and configure kubernetes authentication with the namespace and sa
vault auth enable kubernetes
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"


# caeate policy to read the secret 
vault policy write internal-app - <<EOF
path "internal/data/database/config" {
  capabilities = ["read"]
}
EOF

# create kubernetes authentication role and exit
vault write auth/kubernetes/role/internal-app \
    bound_service_account_names=internal-app \
    bound_service_account_namespaces=default \
    policies=internal-app \
    ttl=24h                                 

exit

# create service acount
kubectl create sa internal-app

# crete the application pod
kubectl apply -f vault_mongo.yaml
