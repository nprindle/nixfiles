{ self }:

{ pkgs, ... }:

{
  imports = [
    (import ./users { inherit self; })
  ];

  system.stateVersion = "22.11";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # enable aarch64-linux emulation
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  networking = {
    hostName = "hecate";
    interfaces = {
      enp2s0.useDHCP = true;
      wlp3s0.useDHCP = true;
    };
  };

  services.tailscale.extraUpFlags = [ "--advertise-exit-node" ];

  hardware = {
    opengl = {
      enable = true;
      driSupport32Bit = true;
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva
      ];
    };

    acpilight.enable = true;

    trackpoint.enable = true;
  };

  virtualisation.virtualbox.host.enable = true;
}
