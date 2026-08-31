{ pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "rpi4";

  # -------------------------------------------------------------------------
  # Network topology:
  #   wlan0 (client, static) → upstream router — internet
  #   eth0  (gateway)        → ASUS router → isolated WiFi clients
  #   NAT: eth0 clients route out via wlan0
  # -------------------------------------------------------------------------

  # wlan0 — WiFi client to upstream router, static IP
  networking.wireless = {
    enable     = true;
    interfaces = [ "wlan0" ];
    # Credentials in /etc/wpa_supplicant.env (not tracked by git):
    #   WIFI_SSID=YourNetworkName
    #   WIFI_PSK=YourPassword
    environmentFile = "/etc/wpa_supplicant.env";
    networks."@WIFI_SSID@".psk = "@WIFI_PSK@";
  };

  networking.interfaces.wlan0 = {
    useDHCP = false;
    ipv4.addresses = [{ address = "YOUR_STATIC_IP"; prefixLength = 24; }];
  };

  networking.defaultGateway = { address = "YOUR_UPSTREAM_GATEWAY"; interface = "wlan0"; };
  networking.nameservers    = [ "127.0.0.1" ];  # pihole handles DNS

  # eth0 — gateway for downstream (ASUS router)
  networking.interfaces.eth0 = {
    useDHCP = false;
    ipv4.addresses = [{ address = "YOUR_DOWNSTREAM_GATEWAY"; prefixLength = 24; }];
  };

  # IP forwarding + NAT
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.nat = {
    enable             = true;
    externalInterface  = "wlan0";
    internalInterfaces = [ "eth0" ];
  };

  # -------------------------------------------------------------------------
  # Containers
  # -------------------------------------------------------------------------
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  # Persistent data dirs — created on every boot if missing
  systemd.tmpfiles.rules = [
    "d /var/lib/pihole/config  0750 root root -"
    "d /var/lib/pihole/dnsmasq 0750 root root -"
    "d /var/lib/vaultwarden    0750 root root -"
  ];

  virtualisation.oci-containers.containers = {

    # Pihole — DNS ad-blocker + DHCP for eth0 subnet
    # Secrets in /etc/pihole.env (not tracked by git):
    #   WEBPASSWORD=yourpassword
    pihole = {
      image        = "pihole/pihole:latest";
      autoStart    = true;
      extraOptions = [ "--network=host" ];  # needs host net for DHCP broadcasts + port 53
      volumes = [
        "/var/lib/pihole/config:/etc/pihole"
        "/var/lib/pihole/dnsmasq:/etc/dnsmasq.d"
      ];
      environmentFiles = [ "/etc/pihole.env" ];
      environment = {
        TZ               = "Europe/Oslo";
        PIHOLE_DNS_      = "8.8.8.8;8.8.4.4";
        DNSMASQ_LISTENING = "single";
        INTERFACE        = "eth0";
        # DHCP (replaces dnsmasq)
        DHCP_ACTIVE      = "true";
        DHCP_START       = "YOUR_DHCP_START";
        DHCP_END         = "YOUR_DHCP_END";
        DHCP_ROUTER      = "YOUR_DOWNSTREAM_GATEWAY";
        DHCP_LEASETIME   = "24";
      };
    };

    # Vaultwarden — self-hosted Bitwarden-compatible password manager
    # Secrets in /etc/vaultwarden.env (not tracked by git):
    #   ADMIN_TOKEN=<argon2id hash>
    #   SMTP_PASSWORD=<password>
    vaultwarden = {
      # GHCR mirror — avoids Docker Hub's authenticated-pull (PAT) requirement
      image            = "ghcr.io/dani-garcia/vaultwarden:latest";
      autoStart        = true;
      ports            = [ "1337:80" ];
      volumes          = [ "/var/lib/vaultwarden:/data" ];
      environmentFiles = [ "/etc/vaultwarden.env" ];
    };

  };

  # -------------------------------------------------------------------------
  # Firewall
  # -------------------------------------------------------------------------
  networking.firewall = {
    enable = true;
    # Port 53 and 80 are covered by trustedInterfaces below
    allowedTCPPorts     = [ 22 1337 ];
    allowedUDPPorts     = [ 53 67 ];  # DNS + DHCP (pihole host-network)
    trustedInterfaces   = [ "eth0" "tailscale0" ];
  };

  system.stateVersion = "26.05";
}
