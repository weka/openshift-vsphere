## Node IPs
loadbalancer_ip = "172.16.1.50"
coredns_ip = "172.16.1.61"
bootstrap_ip = "172.16.1.59"
master_ips = ["172.16.1.52", "172.16.1.53", "172.16.1.54"]
worker_ips = ["172.16.1.55", "172.16.1.56", "172.16.1.57"]

## Cluster configuration
vmware_folder = "coreos"
rhcos_template = "coreos-template"
cluster_slug = "ocp410"
cluster_domain = "coreos.lan"
machine_cidr = "172.16.0.0/21"
netmask ="255.255.248.0"

## DNS
local_dns = "172.16.1.61" # probably the same as coredns_ip
public_dns = "172.16.0.1" # e.g. 1.1.1.1
gateway = "172.16.0.254"

## Ignition paths
## Expects `openshift-install create ignition-configs` to have been run
## probably via generate-configs.sh
bootstrap_ignition_path = "../../openshift/bootstrap.ign"
master_ignition_path = "../../openshift/master.ign"
worker_ignition_path = "../../openshift/worker.ign"
ssh_pubkey_path = "~/.ssh/weka_dev_ssh_key.pub"

worker_cpus = 8
worker_ram_mb = 32768

master_cpus = 4
master_ram_mb = 16384

mgmt_nic_network = "Management"
worker_data_nics_count = 3  # need to have 1 for management and 2 for ionodes
worker_data_nic_network = "DATA"
