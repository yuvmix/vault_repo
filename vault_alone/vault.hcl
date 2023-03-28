ui = true
api_addr = "http://10.92.1.72:8200"
cluster_addr = "http://10.92.1.72:8201"
log_requests_level = "trace"

listener "tcp" {
    address = "10.92.1.72:8200"
    tls_disable = "true"
}

seal "transit" {
  address = "http://10.92.1.71:8200"
  token = "hvs.CAESIBXl4umHdjLvdkfUIUd5VJtnCfrtSHwGAHpt18gda2IaGh4KHGh2cy5NVGUzclBHZEVLa2pkQ1NzR2FnNGhFWjg"
  disable_renewal = "false"

  // key configuration
  key_name = "transit_key_name"
  mount_path = "transit"
  tls_skip_verify = "true"
}

storage "raft" {
  path = "/home/yuval/raft"
  node_id = "raft_node_2"


  retry_join {
    leader_api_addr = "http://10.92.1.72:8200"
  }

  retry_join {
    leader_api_addr = "http://10.92.1.74:8200"
  }

  retry_join {
    leader_api_addr = "http://10.92.1.73:8200"
  }
}

user_lockout "all" {
  lockout_duration = "10m"
  lockout_counter_reset = "10m"
  lockout_treshold = "25"
}
