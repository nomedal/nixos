{ ... }: {
  # SD card root — label set by the NixOS RPi4 image flasher
  fileSystems."/" = {
    device  = "/dev/disk/by-label/NIXOS_SD";
    fsType  = "ext4";
    options = [ "noatime" ];
  };

  # No swap — SD card longevity
  swapDevices = [];

  hardware.enableRedistributableFirmware = true;
}
