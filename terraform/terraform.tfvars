nsx = {
    ip  = "10.114.200.11"
    user = "admin"
    password = "VMware1!VMware1!"
}
nsx_data_vars = {
    transport_zone  = "Overlay-TZ"
    t0_router_name = "Tier-0"
    edge_cluster = "Edge-Cluster-01"
    t1_router_name = "tf-router1"
}
nsx_rs_vars = {
    t0_router_name = "Tier-0"
    t1_router_name = "tf-router1"
}

ipset = ["10.114.200.22", "10.114.200.23", "10.114.200.24"]


nsx_tag_scope = "project"
nsx_tag = "terraform-demo"

vsphere{
    vsphere_user = "administrator@madhu.local"
    vsphere_password = "VMware1!"
    vsphere_ip = "10.114.200.6"
    dc = "Datacenter"
    datastore = "datastore15"
    resource_pool = "Compute/Resources"
    vm_template = "centos-template"
}


app_listen_port = "8443"

db_user = "medicalappuser" # Database details 
db_name = "medicalapp"
db_pass = "VMware1!"

dns_server_list = ["10.114.200.8", "8.8.8.8"]


web = {
    ip = "192.168.244.19"
    gw = "192.168.244.1"
    mask = "24"
    nat_ip = "10.114.200.19"
    vm_name = "web"
    domain = "madhu.local"
    user = "root" # Credentails to access the VM
    pass = "VMware1!"
}

app = {
    ip = "192.168.246.20"
    gw = "192.168.246.1"
    mask = "24"
    nat_ip = "10.114.200.20"
    vm_name = "app"
    domain = "madhu.local"
    user = "root"
    pass = "VMware1!"
}

db = {
    ip = "192.168.247.21"
    gw = "192.168.247.1"
    mask = "24"
    nat_ip = "10.114.200.21"
    vm_name = "db"
    domain = "madhu.local"
    user = "root"
    pass = "VMware1!"
}

