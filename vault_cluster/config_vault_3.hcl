storage "raft" {
   path    = "$demo_home/raft-vault_3/"
   node_id = "vault_3"
}

listener "tcp" {
   address = "127.0.0.3:8200"
   cluster_address = "127.0.0.3:8201"
   tls_disable = true
}

seal "transit" {
   address            = "http://127.0.0.1:8200"
   # token is read from VAULT_TOKEN env
   # token              = ""
   disable_renewal    = "false"
   // Key configuration
   key_name           = "unseal_key"
   mount_path         = "transit/"
}

ui = true
disable_mlock = true
cluster_addr = "http://127.0.0.3:8201"
