ui = true
api_addr = "https://10.92.1.71:8200"
log_requests_level = "trace"

listener "tcp" {
      address = "10.92.1.71:8200"
          tls_disable = "true"
}

storage "file" {
    path = "/mnt/vault/data"
}
