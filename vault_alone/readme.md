vault server -config vault.hcl

vault operator init

# save creds

export VAULT_TOKEN=""
export VAULT_ADDR="<IP>:8200"

# add the unseal keys
vault operator unseal

# add policy for creating token for all other vault instances to connect an auto-unseal
vualt policy write <policy_name> <policy_file>

# crete the token for the other vault instances
vault token create -orphan -policy=<policy_name>

# enable transit
vault secrets enable transit

# create the transit key for auto-unseal
vault write -f transit/keys/<name_of_key>
# vault write transit/encrypt/my-key plaintext=$(echo "my secret data" | base64)


# after the creation of the transit key we can start with the creation of the other vault instances


# running the other servers at the cluster
vault server -config <config_file>
export VAULT_ADDR="<IP>:8200"

# only for one of the servers needs to be initiated and unseal by hand to have the root token and seal keyies
vault operator init --secret_shares=<number_of_unsealkeyies> --secret_threshold=<number_of_unseal_keyies>
vault operator unsael <unseal_key>
export VAULT_TOKEN=""

# than check that the cluster is up and running
vault operator raft list-peers
vault monitor

