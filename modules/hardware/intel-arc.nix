{ config, pkgs, lib, ... }:

{
  # Intel Arc GPU configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver    # LIBVA_DRIVER_NAME=iHD
      intel-compute-runtime # OpenCL
      intel-vaapi-driver    # Legacy, but can help
      vpl-gpu-rt            # Intel oneVPL runtime
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
    ];
  };

  # Environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    LIBVA_DRIVER_NAME = "iHD";
  };

  # Kernel parameters for Intel Arc
  boot.kernelParams = [
    "i915.force_probe=!*"   # Disable i915 for Arc
    "xe.force_probe=*"      # Enable Xe driver for Arc
  ];

  # Intel Arc packages
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
    libva-utils
    nvtopPackages.intel
  ];

  # Power management for laptops
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    };
  };
  # Disable power-profiles-daemon when using TLP
  services.power-profiles-daemon.enable = lib.mkForce false;
}
