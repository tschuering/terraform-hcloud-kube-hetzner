variable "hcloud_token" {
  description = "Hetzner Cloud API Token."
  type        = string
  sensitive   = true
}

variable "k3s_token" {
  description = "k3s master token (must match when restoring a cluster)."
  type        = string
  sensitive   = true
  default     = null
}

variable "microos_x86_snapshot_id" {
  description = "MicroOS x86 snapshot ID to be used. Per default empty, the most recent image created using createkh will be used"
  type        = string
  default     = ""
}

variable "microos_arm_snapshot_id" {
  description = "MicroOS ARM snapshot ID to be used. Per default empty, the most recent image created using createkh will be used"
  type        = string
  default     = ""
}

variable "ssh_port" {
  description = "The main SSH port to connect to the nodes."
  type        = number
  default     = 22

  validation {
    condition     = var.ssh_port >= 0 && var.ssh_port <= 65535
    error_message = "The SSH port must use a valid range from 0 to 65535."
  }
}

variable "ssh_public_key" {
  description = "SSH public Key."
  type        = string
}

variable "ssh_private_key" {
  description = "SSH private Key."
  type        = string
  sensitive   = true
}

variable "ssh_hcloud_key_label" {
  description = "Additional SSH public Keys by hcloud label. e.g. role=admin"
  type        = string
  default     = ""
}

variable "ssh_additional_public_keys" {
  description = "Additional SSH public Keys. Use them to grant other team members root access to your cluster nodes."
  type        = list(string)
  default     = []
}

variable "hcloud_ssh_key_id" {
  description = "If passed, a key already registered within hetzner is used. Otherwise, a new one will be created by the module."
  type        = string
  default     = null
}

variable "ssh_max_auth_tries" {
  description = "The maximum number of authentication attempts permitted per connection."
  type        = number
  default     = 2
}

variable "network_region" {
  description = "Default region for network."
  type        = string
  default     = "eu-central"
}
variable "existing_network_id" {
  # Unfortunately, we need this to be a list or null. If we only use a plain
  # string here, and check that existing_network_id is null, terraform will
  # complain that it cannot set `count` variables based on existing_network_id
  # != null, because that id is an output value from
  # hcloud_network.your_network.id, which terraform will only know after its
  # construction.
  description = "If you want to create the private network before calling this module, you can do so and pass its id here. NOTE: make sure to adapt network_ipv4_cidr accordingly to a range which does not collide with your other nodes."
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = length(var.existing_network_id) == 0 || (can(var.existing_network_id[0]) && length(var.existing_network_id) == 1)
    error_message = "If you pass an existing_network_id, it must be enclosed in square brackets: [id]. This is necessary to be able to unambiguously distinguish between an empty network id (default) and a user-supplied network id."
  }
}
variable "network_ipv4_cidr" {
  description = "The main network cidr that all subnets will be created upon."
  type        = string
  default     = "10.0.0.0/8"
}

variable "cluster_ipv4_cidr" {
  description = "Internal Pod CIDR, used for the controller and currently for calico/cilium."
  type        = string
  default     = "10.42.0.0/16"
}

variable "service_ipv4_cidr" {
  description = "Internal Service CIDR, used for the controller and currently for calico/cilium."
  type        = string
  default     = "10.43.0.0/16"
}

variable "cluster_dns_ipv4" {
  description = "Internal Service IPv4 address of core-dns."
  type        = string
  default     = "10.43.0.10"
}

variable "load_balancer_location" {
  description = "Default load balancer location."
  type        = string
  default     = "fsn1"
}

variable "load_balancer_type" {
  description = "Default load balancer server type."
  type        = string
  default     = "lb11"
}

variable "load_balancer_disable_ipv6" {
  description = "Disable IPv6 for the load balancer."
  type        = bool
  default     = false
}

variable "load_balancer_disable_public_network" {
  description = "Disables the public network of the load balancer."
  type        = bool
  default     = false
}

variable "load_balancer_algorithm_type" {
  description = "Specifies the algorithm type of the load balancer."
  type        = string
  default     = "round_robin"
}

variable "load_balancer_health_check_interval" {
  description = "Specifies the interval at which a health check is performed. Minimum is 3s."
  type        = string
  default     = "15s"
}

variable "load_balancer_health_check_timeout" {
  description = "Specifies the timeout of a single health check. Must not be greater than the health check interval. Minimum is 1s."
  type        = string
  default     = "10s"
}

variable "load_balancer_health_check_retries" {
  description = "Specifies the number of times a health check is retried before a target is marked as unhealthy."
  type        = number
  default     = 3
}

variable "control_plane_nodepools" {
  description = "Number of control plane nodes."
  type = list(object({
    name         = string
    server_type  = string
    location     = string
    backups      = optional(bool)
    labels       = list(string)
    taints       = list(string)
    count        = number
    swap_size    = optional(string, "")
    zram_size    = optional(string, "")
    kubelet_args = optional(list(string), [])
  }))
  default = []
  validation {
    condition = length(
      [for control_plane_nodepool in var.control_plane_nodepools : control_plane_nodepool.name]
      ) == length(
      distinct(
        [for control_plane_nodepool in var.control_plane_nodepools : control_plane_nodepool.name]
      )
    )
    error_message = "Names in agent_nodepools must be unique."
  }
}

variable "agent_nodepools" {
  description = "Number of agent nodes."
  type = list(object({
    name                 = string
    server_type          = string
    location             = string
    backups              = optional(bool)
    floating_ip          = optional(bool)
    labels               = list(string)
    taints               = list(string)
    count                = number
    longhorn_volume_size = optional(number)
    swap_size            = optional(string, "")
    zram_size            = optional(string, "")
    kubelet_args         = optional(list(string), [])
  }))
  default = []
  validation {
    condition = length(
      [for agent_nodepool in var.agent_nodepools : agent_nodepool.name]
      ) == length(
      distinct(
        [for agent_nodepool in var.agent_nodepools : agent_nodepool.name]
      )
    )
    error_message = "Names in agent_nodepools must be unique."
  }
}

variable "cluster_autoscaler_image" {
  type        = string
  default     = "ghcr.io/kube-hetzner/autoscaler/cluster-autoscaler"
  description = "Image of Kubernetes Cluster Autoscaler for Hetzner Cloud to be used."
}

variable "cluster_autoscaler_version" {
  type        = string
  default     = "20231027"
  description = "Version of Kubernetes Cluster Autoscaler for Hetzner Cloud. Should be aligned with Kubernetes version"
}

variable "cluster_autoscaler_log_level" {
  description = "Verbosity level of the logs for cluster-autoscaler"
  type        = number
  default     = 4

  validation {
    condition     = var.cluster_autoscaler_log_level >= 0 && var.cluster_autoscaler_log_level <= 5
    error_message = "The log level must be between 0 and 5."
  }
}

variable "cluster_autoscaler_log_to_stderr" {
  description = "Determines whether to log to stderr or not"
  type        = bool
  default     = true
}

variable "cluster_autoscaler_stderr_threshold" {
  description = "Severity level above which logs are sent to stderr instead of stdout"
  type        = string
  default     = "INFO"

  validation {
    condition     = var.cluster_autoscaler_stderr_threshold == "INFO" || var.cluster_autoscaler_stderr_threshold == "WARNING" || var.cluster_autoscaler_stderr_threshold == "ERROR" || var.cluster_autoscaler_stderr_threshold == "FATAL"
    error_message = "The stderr threshold must be one of the following: INFO, WARNING, ERROR, FATAL."
  }
}

variable "cluster_autoscaler_extra_args" {
  type        = list(string)
  default     = []
  description = "Extra arguments for the Cluster Autoscaler deployment."
}

variable "autoscaler_nodepools" {
  description = "Cluster autoscaler nodepools."
  type = list(object({
    name        = string
    server_type = string
    location    = string
    min_nodes   = number
    max_nodes   = number
    labels      = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = []
}

variable "autoscaler_labels" {
  description = "Labels for nodes created by the Cluster Autoscaler."
  type        = list(string)
  default     = []
}

variable "autoscaler_taints" {
  description = "Taints for nodes created by the Cluster Autoscaler."
  type        = list(string)
  default     = []
}

variable "hetzner_ccm_version" {
  type        = string
  default     = null
  description = "Version of Kubernetes Cloud Controller Manager for Hetzner Cloud."
}

variable "hetzner_csi_version" {
  type        = string
  default     = null
  description = "Version of Container Storage Interface driver for Hetzner Cloud."
}

variable "restrict_outbound_traffic" {
  type        = bool
  default     = true
  description = "Whether or not to restrict the outbound traffic."
}

variable "enable_klipper_metal_lb" {
  type        = bool
  default     = false
  description = "Use klipper load balancer."
}

variable "etcd_s3_backup" {
  description = "Etcd cluster state backup to S3 storage"
  type        = map(any)
  sensitive   = true
  default     = {}
}

variable "ingress_controller" {
  type        = string
  default     = "traefik"
  description = "The name of the ingress controller."

  validation {
    condition     = contains(["traefik", "nginx", "none"], var.ingress_controller)
    error_message = "Must be one of \"traefik\" or \"nginx\" or \"none\""
  }
}

variable "ingress_replica_count" {
  type        = number
  default     = 0
  description = "Number of replicas per ingress controller. 0 means autodetect based on the number of agent nodes."

  validation {
    condition     = var.ingress_replica_count >= 0
    error_message = "Number of ingress replicas can't be below 0."
  }
}

variable "ingress_max_replica_count" {
  type        = number
  default     = 10
  description = "Number of maximum replicas per ingress controller. Used for ingress HPA. Must be higher than number of replicas."

  validation {
    condition     = var.ingress_max_replica_count >= 0
    error_message = "Number of ingress maximum replicas can't be below 0."
  }
}

variable "traefik_autoscaling" {
  type        = bool
  default     = true
  description = "Should traefik enable Horizontal Pod Autoscaler."
}

variable "traefik_redirect_to_https" {
  type        = bool
  default     = true
  description = "Should traefik redirect http traffic to https."
}

variable "traefik_pod_disruption_budget" {
  type        = bool
  default     = true
  description = "Should traefik enable pod disruption budget. Default values are maxUnavailable: 33% and minAvailable: 1."
}

variable "traefik_resource_limits" {
  type        = bool
  default     = true
  description = "Should traefik enable default resource requests and limits. Default values are requests: 100m & 50Mi and limits: 300m & 150Mi."
}

variable "traefik_additional_ports" {
  type = list(object({
    name        = string
    port        = number
    exposedPort = number
  }))
  default     = []
  description = "Additional ports to pass to Traefik. These are the ones that go into the ports section of the Traefik helm values file."
}

variable "traefik_additional_options" {
  type        = list(string)
  default     = []
  description = "Additional options to pass to Traefik as a list of strings. These are the ones that go into the additionalArguments section of the Traefik helm values file."
}

variable "traefik_additional_trusted_ips" {
  type        = list(string)
  default     = []
  description = "Additional Trusted IPs to pass to Traefik. These are the ones that go into the trustedIPs section of the Traefik helm values file."
}

variable "traefik_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Traefik as 'valuesContent' at the HelmChart."
}

variable "nginx_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to nginx as 'valuesContent' at the HelmChart."
}

variable "allow_scheduling_on_control_plane" {
  type        = bool
  default     = false
  description = "Whether to allow non-control-plane workloads to run on the control-plane nodes."
}

variable "enable_metrics_server" {
  type        = bool
  default     = true
  description = "Whether to enable or disable k3s metric server."
}

variable "initial_k3s_channel" {
  type        = string
  default     = "v1.27"
  description = "Allows you to specify an initial k3s channel."

  validation {
    condition     = contains(["stable", "latest", "testing", "v1.16", "v1.17", "v1.18", "v1.19", "v1.20", "v1.21", "v1.22", "v1.23", "v1.24", "v1.25", "v1.26", "v1.27"], var.initial_k3s_channel)
    error_message = "The initial k3s channel must be one of stable, latest or testing, or any of the minor kube versions like v1.26."
  }
}

variable "automatically_upgrade_k3s" {
  type        = bool
  default     = true
  description = "Whether to automatically upgrade k3s based on the selected channel."
}

variable "automatically_upgrade_os" {
  type        = bool
  default     = true
  description = "Whether to enable or disable automatic os updates. Defaults to true. Should be disabled for single-node clusters"
}

variable "extra_firewall_rules" {
  type        = list(any)
  default     = []
  description = "Additional firewall rules to apply to the cluster."
}

variable "firewall_kube_api_source" {
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
  description = "Source networks that have Kube API access to the servers."
}

variable "firewall_ssh_source" {
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
  description = "Source networks that have SSH access to the servers."
}

variable "use_cluster_name_in_node_name" {
  type        = bool
  default     = true
  description = "Whether to use the cluster name in the node name."
}

variable "cluster_name" {
  type        = string
  default     = "k3s"
  description = "Name of the cluster."

  validation {
    condition     = can(regex("^[a-z0-9\\-]+$", var.cluster_name))
    error_message = "The cluster name must be in the form of lowercase alphanumeric characters and/or dashes."
  }
}

variable "base_domain" {
  type        = string
  default     = ""
  description = "Base domain of the cluster, used for reserve dns."

  validation {
    condition     = can(regex("^(?:(?:(?:[A-Za-z0-9])|(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]+)?[A-Za-z0-9]))+(\\.))+([A-Za-z]{2,})([\\/?])?([\\/?][A-Za-z0-9\\-%._~:\\/?#\\[\\]@!\\$&\\'\\(\\)\\*\\+,;=]+)?$", var.base_domain)) || var.base_domain == ""
    error_message = "It must be a valid domain name (FQDN)."
  }
}

variable "placement_group_disable" {
  type        = bool
  default     = false
  description = "Whether to disable placement groups."
}

variable "disable_network_policy" {
  type        = bool
  default     = false
  description = "Disable k3s default network policy controller (default false, automatically true for calico and cilium)."
}

variable "cni_plugin" {
  type        = string
  default     = "flannel"
  description = "CNI plugin for k3s."

  validation {
    condition     = contains(["flannel", "calico", "cilium"], var.cni_plugin)
    error_message = "The cni_plugin must be one of \"flannel\", \"calico\", or \"cilium\"."
  }
}

variable "cilium_egress_gateway_enabled" {
  type        = bool
  default     = false
  description = "Enables egress gateway to redirect and SNAT the traffic that leaves the cluster."
}

variable "cilium_ipv4_native_routing_cidr" {
  type        = string
  default     = null
  description = "Used when Cilium is configured in native routing mode. The CNI assumes that the underlying network stack will forward packets to this destination without the need to apply SNAT. Default: value of \"cluster_ipv4_cidr\""
}

variable "cilium_routing_mode" {
  type        = string
  default     = "tunnel"
  description = "Set native-routing mode (\"native\") or tunneling mode (\"tunnel\")."

  validation {
    condition     = contains(["tunnel", "native"], var.cilium_routing_mode)
    error_message = "The cilium_routing_mode must be one of \"tunnel\" or \"native\"."
  }
}

variable "cilium_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Cilium as 'valuesContent' at the HelmChart."
}

variable "cilium_version" {
  type        = string
  default     = "v1.14.0"
  description = "Version of Cilium."
}

variable "calico_values" {
  type        = string
  default     = ""
  description = "Just a stub for a future helm implementation. Now it can be used to replace the calico kustomize patch of the calico manifest."
}

variable "enable_longhorn" {
  type        = bool
  default     = false
  description = "Whether or not to enable Longhorn."
}

variable "longhorn_repository" {
  type        = string
  default     = "https://charts.longhorn.io"
  description = "By default the official chart which may be incompatible with rancher is used. If you need to fully support rancher switch to https://charts.rancher.io."
}

variable "longhorn_namespace" {
  type        = string
  default     = "longhorn-system"
  description = "Namespace for longhorn deployment, defaults to 'longhorn-system'"
}

variable "longhorn_fstype" {
  type        = string
  default     = "ext4"
  description = "The longhorn fstype."

  validation {
    condition     = contains(["ext4", "xfs"], var.longhorn_fstype)
    error_message = "Must be one of \"ext4\" or \"xfs\""
  }
}

variable "longhorn_replica_count" {
  type        = number
  default     = 3
  description = "Number of replicas per longhorn volume."

  validation {
    condition     = var.longhorn_replica_count > 0
    error_message = "Number of longhorn replicas can't be below 1."
  }
}

variable "longhorn_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to longhorn as 'valuesContent' at the HelmChart."
}

variable "disable_hetzner_csi" {
  type        = bool
  default     = false
  description = "Disable hetzner csi driver."
}

variable "enable_csi_driver_smb" {
  type        = bool
  default     = false
  description = "Whether or not to enable csi-driver-smb."
}

variable "csi_driver_smb_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to csi-driver-smb as 'valuesContent' at the HelmChart."
}

variable "enable_cert_manager" {
  type        = bool
  default     = true
  description = "Enable cert manager."
}

variable "cert_manager_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Cert-Manager as 'valuesContent' at the HelmChart."
}

variable "enable_rancher" {
  type        = bool
  default     = false
  description = "Enable rancher."
}

variable "rancher_install_channel" {
  type        = string
  default     = "stable"
  description = "The rancher installation channel."

  validation {
    condition     = contains(["stable", "latest"], var.rancher_install_channel)
    error_message = "The allowed values for the Rancher install channel are stable or latest."
  }
}

variable "rancher_hostname" {
  type        = string
  default     = ""
  description = "The rancher hostname."

  validation {
    condition     = can(regex("^(?:(?:(?:[A-Za-z0-9])|(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]+)?[A-Za-z0-9]))+(\\.))+([A-Za-z]{2,})([\\/?])?([\\/?][A-Za-z0-9\\-%._~:\\/?#\\[\\]@!\\$&\\'\\(\\)\\*\\+,;=]+)?$", var.rancher_hostname)) || var.rancher_hostname == ""
    error_message = "It must be a valid domain name (FQDN)."
  }
}

variable "lb_hostname" {
  type        = string
  default     = ""
  description = "The Hetzner Load Balancer hostname, for either Traefik or Ingress-Nginx."

  validation {
    condition     = can(regex("^(?:(?:(?:[A-Za-z0-9])|(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]+)?[A-Za-z0-9]))+(\\.))+([A-Za-z]{2,})([\\/?])?([\\/?][A-Za-z0-9\\-%._~:\\/?#\\[\\]@!\\$&\\'\\(\\)\\*\\+,;=]+)?$", var.lb_hostname)) || var.lb_hostname == ""
    error_message = "It must be a valid domain name (FQDN)."
  }
}

variable "rancher_registration_manifest_url" {
  type        = string
  description = "The url of a rancher registration manifest to apply. (see https://rancher.com/docs/rancher/v2.6/en/cluster-provisioning/registered-clusters/)."
  default     = ""
  sensitive   = true
}

variable "rancher_bootstrap_password" {
  type        = string
  default     = ""
  description = "Rancher bootstrap password."
  sensitive   = true

  validation {
    condition     = (length(var.rancher_bootstrap_password) >= 48) || (length(var.rancher_bootstrap_password) == 0)
    error_message = "The Rancher bootstrap password must be at least 48 characters long."
  }
}

variable "rancher_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Rancher as 'valuesContent' at the HelmChart."
}

variable "kured_version" {
  type        = string
  default     = null
  description = "Version of Kured."
}

variable "kured_options" {
  type    = map(string)
  default = {}
}

variable "block_icmp_ping_in" {
  type        = bool
  default     = false
  description = "Block entering ICMP ping."
}

variable "use_control_plane_lb" {
  type        = bool
  default     = false
  description = "When this is enabled, rather than the first node, all external traffic will be routed via a control-plane loadbalancer, allowing for high availability."
}

variable "control_plane_lb_type" {
  type        = string
  default     = "lb11"
  description = "The type of load balancer to use for the control plane load balancer. Defaults to lb11, which is the cheapest one."
}

variable "control_plane_lb_enable_public_interface" {
  type        = bool
  default     = true
  description = "Enable or disable public interface for the control plane load balancer . Defaults to true."
}

variable "dns_servers" {
  type        = list(string)
  default     = []
  description = "IP Addresses to use for the DNS Servers, set to an empty list to use the ones provided by Hetzner. The length is limited to 3 entries, more entries is not supported by kubernetes"

  validation {
    condition     = length(var.dns_servers) <= 3
    error_message = "The list must have no more than 3 items."
  }
}

variable "address_for_connectivity_test" {
  type        = string
  default     = "1.1.1.1"
  description = "Before installing k3s, we actually verify that there is internet connectivity. By default we ping 1.1.1.1, but if you use a proxy, you may simply want to ping that proxy instead (assuming that the proxy has its own checks for internet connectivity)."
}

variable "additional_k3s_environment" {
  type        = map(any)
  default     = {}
  description = "Additional environment variables for the k3s binary. See for example https://docs.k3s.io/advanced#configuring-an-http-proxy ."
}

variable "preinstall_exec" {
  type        = list(string)
  default     = []
  description = "Additional to execute before the install calls, for example fetching and installing certs."
}

variable "postinstall_exec" {
  type        = list(string)
  default     = []
  description = "Additional to execute after the install calls, for example restoring a backup."
}


variable "extra_kustomize_deployment_commands" {
  type        = string
  default     = ""
  description = "Commands to be executed after the `kubectl apply -k <dir>` step."
}

variable "extra_kustomize_parameters" {
  type        = map(any)
  default     = {}
  description = "All values will be passed to the `kustomization.tmp.yml` template."
}

variable "create_kubeconfig" {
  type        = bool
  default     = true
  description = "Create the kubeconfig as a local file resource. Should be disabled for automatic runs."
}

variable "create_kustomization" {
  type        = bool
  default     = true
  description = "Create the kustomization backup as a local file resource. Should be disabled for automatic runs."
}

variable "export_values" {
  type        = bool
  default     = false
  description = "Export for deployment used values.yaml-files as local files."
}

variable "enable_wireguard" {
  type        = bool
  default     = false
  description = "Use wireguard-native as the backend for CNI."
}

variable "control_planes_custom_config" {
  type        = any
  default     = {}
  description = "Custom control plane configuration e.g to allow etcd monitoring."
}

variable "k3s_registries" {
  description = "K3S registries.yml contents. It used to access private docker registries."
  default     = " "
  type        = string
}

variable "additional_tls_sans" {
  description = "Additional TLS SANs to allow connection to control-plane through it."
  default     = []
  type        = list(string)
}

variable "calico_version" {
  type        = string
  default     = null
  description = "Version of Calico."
}

variable "k3s_exec_server_args" {
  type        = string
  default     = ""
  description = "The control plane is started with `k3s server {k3s_exec_server_args}`. Use this to add kube-apiserver-arg for example."
}

variable "k3s_exec_agent_args" {
  type        = string
  default     = ""
  description = "Agents nodes are started with `k3s agent {k3s_exec_agent_args}`. Use this to add kubelet-arg for example."
}

variable "k3s_global_kubelet_args" {
  type        = list(string)
  default     = []
  description = "Global kubelet args for all nodes."
}

variable "k3s_control_plane_kubelet_args" {
  type        = list(string)
  default     = []
  description = "Kubelet args for control plane nodes."
}

variable "k3s_agent_kubelet_args" {
  type        = list(string)
  default     = []
  description = "Kubelet args for agent nodes."
}

variable "ingress_target_namespace" {
  type        = string
  default     = ""
  description = "The namespace to deploy the ingress controller to. Defaults to ingress name."
}
