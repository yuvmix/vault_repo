# preparations
get docker, minikube, helm, kubectl

## docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER && newgrp docker

## minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

## helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

## kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client

## clone that repo and build the image in it
git clone https://github.com/raakatz/vault-mongodb.git



# deploying mongodb 
## start the minikube
minikube start

## create the mongodb pod 
kubectl run   --port 27017 --port 28017  --image=yuvalammatrix/mongo:latest --env=MONGO_INITDB_ROOT_USERNAME="mdbadmin" --env=MONGO_INITDB_ROOT_PASSWORD="hQ97T9JJKZoqnFn2NXE" --env=MONGO_INITDB_DATABASE="database-mongodb"  -l='app=database-mongodb' database-mongodb

## create mongodb service
kubectl create service nodeport database-mongodb --tcp 27017:27017  -o yaml | kubectl set selector --local -f - app=mongo -o yaml



# deploying vault and vault-agent-injector
## get, update and install this helm chart
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault --set "server.dev.enabled=true"

## now you have the vault dev server and vault-agent-injector, check they are running
kubectl get pods



# create your secret in vault
## enter the container vault-0
kubectl exec -it vault-0 -- /bin/sh

## vault secrets enable database
vault secrets enable database

## configure mongodb secret engine
vault write database/config/database-mongodb \
    plugin_name=mongodb-database-plugin \
    allowed_roles="admin" \
    connection_url="mongodb://{{username}}:{{password}}@database-mongodb:27017/admin?tls=false" \
    username="mdbadmin" \
    password="hQ97T9JJKZoqnFn2NXE"

## create role for mongodb
vault write database/roles/admin \
    db_name=database-mongodb \
    creation_statements='{ "db": "admin", "roles": [{ "role": "readWrite" }, {"role": "read", "db": "foo"}] }' \
    default_ttl="1h" \
    max_ttl="24h"
    
   
   
# configure kubernetes authentication in vault
## enable kubernetes auth
vault auth enable kubernetes

## bound to port of minikube
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
  
## add policy 
vault policy write vault-sa -<<EOF
## Required: Get credentials from the database secrets engine for 'admin' role.
path "database/creds/admin" {
  capabilities = [ "read" ]
}
EOF

## create kubernetes authentication role
vault write auth/kubernetes/role/vault-sa \
    bound_service_account_names=vault-sa \
    bound_service_account_namespaces=default \
    policies=vault-sa \
    ttl=24h

## create the service acount
kubectl create sa vault-sa
                                   

                                   
# crete the application pod
kubectl apply -f vault-mongo.yaml
                                   
## check vualt-agent logs                                   
kubectl logs \
    $(kubectl get pod -l app=database-mongodb -o jsonpath="{.items[0].metadata.name}") \
    --container vault-agent
