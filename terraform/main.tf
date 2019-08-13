# Configure the VMware NSX-T Provider
provider "nsxt" {
    host = "${var.nsx["ip"]}"
    username = "${var.nsx["user"]}"
    password = "${var.nsx["password"]}"
    allow_unverified_ssl = true
}

# Create the data sources we will need to refer to later
data "nsxt_transport_zone" "overlay_tz" {
    display_name = "${var.nsx_data_vars["transport_zone"]}"
}
data "nsxt_logical_tier0_router" "tier0_router" {
  display_name = "${var.nsx_data_vars["t0_router_name"]}"
}
data "nsxt_edge_cluster" "edge_cluster1" {
    display_name = "${var.nsx_data_vars["edge_cluster"]}"
}

# Create Web Tier NSX-T Logical Switch
resource "nsxt_logical_switch" "web" {
    admin_state = "UP"
    description = "LS created by Terraform"
    display_name = "web-tier"
    transport_zone_id = "${data.nsxt_transport_zone.overlay_tz.id}"
    replication_mode = "MTEP"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
    tag {
        scope = "tier"
        tag = "web"
    }
}

# Create App Tier NSX-T Logical Switch
resource "nsxt_logical_switch" "app" {
    admin_state = "UP"
    description = "LS created by Terraform"
    display_name = "app-tier"
    transport_zone_id = "${data.nsxt_transport_zone.overlay_tz.id}"
    replication_mode = "MTEP"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
    tag {
        scope = "tier"
        tag = "app"
    }
}


# Create DB Tier NSX-T Logical Switch
resource "nsxt_logical_switch" "db" {
    admin_state = "UP"
    description = "LS created by Terraform"
    display_name = "db-tier"
    transport_zone_id = "${data.nsxt_transport_zone.overlay_tz.id}"
    replication_mode = "MTEP"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
    tag {
        scope = "tier"
        tag = "db"
    }
}


# Create T1 router
resource "nsxt_logical_tier1_router" "tier1_router" {
  description                 = "Tier1 router provisioned by Terraform"
  display_name                = "${var.nsx_rs_vars["t1_router_name"]}"
  failover_mode               = "PREEMPTIVE"
  edge_cluster_id             = "${data.nsxt_edge_cluster.edge_cluster1.id}"
  enable_router_advertisement = true
  advertise_connected_routes  = true
  advertise_static_routes     = true
  advertise_nat_routes        = true
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create a port on the T0 router. We will connect the T1 router to this port
resource "nsxt_logical_router_link_port_on_tier0" "link_port_tier0" {
  description       = "TIER0_PORT1 provisioned by Terraform"
  display_name      = "TIER0_PORT1"
  logical_router_id = "${data.nsxt_logical_tier0_router.tier0_router.id}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create a T1 uplink port and connect it to T0 router
resource "nsxt_logical_router_link_port_on_tier1" "link_port_tier1" {
  description                   = "TIER1_PORT1 provisioned by Terraform"
  display_name                  = "TIER1_PORT1"
  logical_router_id             = "${nsxt_logical_tier1_router.tier1_router.id}"
  linked_logical_router_port_id = "${nsxt_logical_router_link_port_on_tier0.link_port_tier0.id}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create a switchport on App logical switch
resource "nsxt_logical_port" "logical_port1" {
  admin_state       = "UP"
  description       = "LP1 provisioned by Terraform"
  display_name      = "AppToT1"
  logical_switch_id = "${nsxt_logical_switch.app.id}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create downlink port on the T1 router and connect it to the switchport we created earlier for App Tier
resource "nsxt_logical_router_downlink_port" "downlink_port" {
  description                   = "DP1 provisioned by Terraform"
  display_name                  = "DP1"
  logical_router_id             = "${nsxt_logical_tier1_router.tier1_router.id}"
  linked_logical_switch_port_id = "${nsxt_logical_port.logical_port1.id}"
  ip_address                    = "${var.app["gw"]}/${var.app["mask"]}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create a switchport on Web logical switch
resource "nsxt_logical_port" "logical_port2" {
  admin_state       = "UP"
  description       = "LP1 provisioned by Terraform"
  display_name      = "WebToT1"
  logical_switch_id = "${nsxt_logical_switch.web.id}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create downlink port on the T1 router and connect it to the switchport we created earlier
resource "nsxt_logical_router_downlink_port" "downlink_port2" {
  description                   = "DP2 provisioned by Terraform"
  display_name                  = "DP2"
  logical_router_id             = "${nsxt_logical_tier1_router.tier1_router.id}"
  linked_logical_switch_port_id = "${nsxt_logical_port.logical_port2.id}"
  ip_address                    = "${var.web["gw"]}/${var.web["mask"]}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create a switchport on DB logical switch
resource "nsxt_logical_port" "logical_port3" {
  admin_state       = "UP"
  description       = "LP3 provisioned by Terraform"
  display_name      = "DBToT1"
  logical_switch_id = "${nsxt_logical_switch.db.id}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create downlink port on the T1 router and connect it to the switchport we created earlier
resource "nsxt_logical_router_downlink_port" "downlink_port3" {
  description                   = "DP3 provisioned by Terraform"
  display_name                  = "DP3"
  logical_router_id             = "${nsxt_logical_tier1_router.tier1_router.id}"
  linked_logical_switch_port_id = "${nsxt_logical_port.logical_port3.id}"
  ip_address                    = "${var.db["gw"]}/${var.db["mask"]}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}


# Create NSGROUP with dynamic membership criteria
# all Virtual Machines with the specific tag and scope
resource "nsxt_ns_group" "nsgroup" {
  description  = "NSGroup provisioned by Terraform"
  display_name = "terraform-demo-sg"
  membership_criteria {
    target_type = "VirtualMachine"
    scope       = "${var.nsx_tag_scope}"
    tag         = "${var.nsx_tag}"
  }
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create Web NSGROUP
resource "nsxt_ns_group" "webnsgroup" {
  description  = "NSGroup provisioned by Terraform"
  display_name = "web-terraform-demo-sg"
  membership_criteria {
    target_type = "VirtualMachine"
    scope       = "tier"
    tag         = "web"
  }
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}
# Create App NSGROUP
resource "nsxt_ns_group" "appnsgroup" {
  description  = "NSGroup provisioned by Terraform"
  display_name = "app-terraform-demo-sg"
  membership_criteria {
    target_type = "VirtualMachine"
    scope       = "tier"
    tag         = "app"
  }
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}
# Create DB NSGROUP
resource "nsxt_ns_group" "dbnsgroup" {
  description  = "NSGroup provisioned by Terraform"
  display_name = "db-terraform-demo-sg"
  membership_criteria {
    target_type = "VirtualMachine"
    scope       = "tier"
    tag         = "db"
  }
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create custom NSService for App service that listens on port 8443
resource "nsxt_l4_port_set_ns_service" "app" {
  description       = "L4 Port range provisioned by Terraform"
  display_name      = "App Service"
  protocol          = "TCP"
  destination_ports = ["${var.app_listen_port}"]
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create data sourcees for some NSServices that we need to create FW rules
data "nsxt_ns_service" "https" {
  display_name = "HTTPS"
}

data "nsxt_ns_service" "mysql" {
  display_name = "MySQL"
}

data "nsxt_ns_service" "ssh" {
  display_name = "SSH"
}

# Create IP-SET with some ip addresses
# we will use in for fw rules allowing communication to this external IPs
resource "nsxt_ip_set" "ip_set" {
  description  = "Infrastructure IPSET provisioned by Terraform"
  display_name = "Infra"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
  ip_addresses = "${var.ipset}"
}

# Create a Firewall Section
# All rules of this section will be applied to the VMs that are members of the NSGroup we created earlier
resource "nsxt_firewall_section" "firewall_section" {
  description  = "FS provisioned by Terraform"
  display_name = "Terraform Demo FW Section"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
  applied_to {
    target_type = "NSGroup"
    target_id   = "${nsxt_ns_group.nsgroup.id}"
  }

  section_type = "LAYER3"
  stateful     = true


# Allow communication to my VMs only on the ports we defined earlier as NSService
  rule {
    display_name = "Allow HTTPs"
    description  = "In going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    destination {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.webnsgroup.id}"
    }
    service {
      target_type = "NSService"
      target_id   = "${data.nsxt_ns_service.https.id}"
    }
  }
  rule {
    display_name = "Allow SSH"
    description  = "In going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    destination {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.nsgroup.id}"
    }
    service {
      target_type = "NSService"
      target_id   = "${data.nsxt_ns_service.ssh.id}"
    }
  }
  rule {
    display_name = "Allow Web to App"
    description  = "In going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    source {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.webnsgroup.id}"
    }
    destination {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.appnsgroup.id}"
    }
    service {
      target_type = "NSService"
      target_id   = "${nsxt_l4_port_set_ns_service.app.id}"
    }
  }
  rule {
    display_name = "Allow App to DB"
    description  = "In going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    source {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.appnsgroup.id}"
    }
    destination {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.dbnsgroup.id}"
    }
    service {
      target_type = "NSService"
      target_id   = "${data.nsxt_ns_service.mysql.id}"
    }
  }

# Allow the ip addresses defined in the IP-SET to communicate to my VMs on all ports
  rule {
    display_name = "Allow Infrastructure"
    description  = "Allow DNS and Management Servers"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    source {
      target_type = "IPSet"
      target_id   = "${nsxt_ip_set.ip_set.id}"
    }
    destination {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.nsgroup.id}"
    }
  }
  
# Allow all communication from my VMs to everywhere
  rule {
    display_name = "Allow out"
    description  = "Out going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"

    source {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.nsgroup.id}"
    }
  }

# REJECT everything that is not explicitelly allowed above and log a message
  rule {
    display_name = "Deny ANY"
    description  = "Default Deny the traffic"
    action       = "REJECT"
    logged       = true
    ip_protocol  = "IPV4"
  }
}

# Create 1 to 1 NAT for Web VM
resource "nsxt_nat_rule" "rule1" {
  count = "${var.web["nat_ip"] != "" ? 1 : 0}"
  logical_router_id         = "${nsxt_logical_tier1_router.tier1_router.id}"
  description               = "1 to 1 NAT provisioned by Terraform"
  display_name              = "Web 1to1-in"
  action                    = "SNAT"
  enabled                   = true
  logging                   = false
  nat_pass                  = true
  translated_network        =  "${var.web["nat_ip"]}"
  match_source_network = "${var.web["ip"]}/32"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

resource "nsxt_nat_rule" "rule2" {
  count = "${var.web["nat_ip"] != "" ? 1 : 0}"
  logical_router_id         = "${nsxt_logical_tier1_router.tier1_router.id}"
  description               = "1 to 1 NAT provisioned by Terraform"
  display_name              = "Web 1to1-out"
  action                    = "DNAT"
  enabled                   = true
  logging                   = false
  nat_pass                  = true
  translated_network        = "${var.web["ip"]}"
  match_destination_network = "${var.web["nat_ip"]}/32"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}


# Create 1 to 1 NAT for App VM
resource "nsxt_nat_rule" "rule3" {
  count = "${var.app["nat_ip"] != "" ? 1 : 0}"
  logical_router_id         = "${nsxt_logical_tier1_router.tier1_router.id}"
  description               = "1 to 1 NAT provisioned by Terraform"
  display_name              = "App 1to1-in"
  action                    = "SNAT"
  enabled                   = true
  logging                   = false
  nat_pass                  = true
  translated_network        =  "${var.app["nat_ip"]}"
  match_source_network = "${var.app["ip"]}/32"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

resource "nsxt_nat_rule" "rule4" {
  count = "${var.app["nat_ip"] != "" ? 1 : 0}"
  logical_router_id         = "${nsxt_logical_tier1_router.tier1_router.id}"
  description               = "1 to 1 NAT provisioned by Terraform"
  display_name              = "App 1to1-out"
  action                    = "DNAT"
  enabled                   = true
  logging                   = false
  nat_pass                  = true
  translated_network        = "${var.app["ip"]}"
  match_destination_network = "${var.app["nat_ip"]}/32"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create 1 to 1 NAT for DB VM
resource "nsxt_nat_rule" "rule5" {
  count = "${var.db["nat_ip"] != "" ? 1 : 0}"
  logical_router_id         = "${nsxt_logical_tier1_router.tier1_router.id}"
  description               = "1 to 1 NAT provisioned by Terraform"
  display_name              = "DB 1to1-in"
  action                    = "SNAT"
  enabled                   = true
  logging                   = false
  nat_pass                  = true
  translated_network        =  "${var.db["nat_ip"]}"
  match_source_network      = "${var.db["ip"]}/32"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

resource "nsxt_nat_rule" "rule6" {
  count = "${var.db["nat_ip"] != "" ? 1 : 0}"
  logical_router_id         = "${nsxt_logical_tier1_router.tier1_router.id}"
  description               = "1 to 1 NAT provisioned by Terraform"
  display_name              = "DB 1to1-out"
  action                    = "DNAT"
  enabled                   = true
  logging                   = false
  nat_pass                  = true
  translated_network        = "${var.db["ip"]}"
  match_destination_network = "${var.db["nat_ip"]}/32"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}
