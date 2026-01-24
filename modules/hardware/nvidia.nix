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

    # Use the stable driver
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Enable nvidia-settings
    nvidiaSettings = true;
  };

  # OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Environment variables for NVIDIA on Wayland
  environment.sessionVariables = {
    # For Electron apps on Wayland
    NIXOS_OZONE_WL = "1";
    # NVIDIA specific
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    # Explicit sync for KDE Plasma 6
    KWIN_DRM_USE_EGL_STREAMS = "0";
  };

  # Packages for NVIDIA
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
    nvidia-vaapi-driver
    libva
    libva-utils
  ];
}
