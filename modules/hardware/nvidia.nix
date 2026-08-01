{ config, pkgs, lib, ... }:

{
  # NVIDIA GPU configuration
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Use open source kernel modules (nvidia-open)
    open = true;

    # Modesetting is required for Wayland
    modesetting.enable = true;

    # Power management (experimental)
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Use the latest driver — switched from .stable (595.84) 2026-07-24 after
    # repeated crashes (green screen corruption) traced to Xid 56 display engine
    # errors caused by GPU BAR1 mapping exhaustion during Brave hardware video
    # decode (nvidia-vaapi-driver / nvidia-drm). .production is pinned to the
    # same 595.84 as .stable so it wouldn't help; .latest is a newer branch
    # that may contain a fix for the BAR1 leak.
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # Enable nvidia-settings
    nvidiaSettings = true;
  };

  # OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Environment variables for NVIDIA on Wayland/Hyprland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # Packages for NVIDIA
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
    nvidia-vaapi-driver
    libva
    libva-utils
  ];
}
