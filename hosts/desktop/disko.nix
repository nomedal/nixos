# Declarative disk layout for desktop (nvme0n1, 1TB NVMe)
#
# Layout:
#   nvme0n1p1  1G    EFI/boot  vfat        /boot
#   nvme0n1p2  rest  LUKS      btrfs
#     @         /               compress=zstd noatime
#     @home     /home           compress=zstd noatime
#     @nix      /nix            compress=zstd noatime
#     @swap     /.swapvol       16G swapfile
#
# sda, sdb (4TB HDDs, NTFS) and sdc, sdd are NOT managed by disko.
# Wire them up in fileSystems after install if needed.
#
# Before running disko, verify the device:
#   lsblk | grep nvme
# Then: sudo nix run github:nix-community/disko -- --mode destroy,format,mount hosts/desktop/disko.nix
{ ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-L" "nixos" "-f" ];
                  subvolumes = {
                    "@" = {
                      mountpoint = "/";
                      mountOptions = [ "subvol=@" "compress=zstd" "noatime" ];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "subvol=@home" "compress=zstd" "noatime" ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "subvol=@nix" "compress=zstd" "noatime" ];
                    };
                    "@swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "16G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
