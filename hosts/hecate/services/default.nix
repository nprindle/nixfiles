{ pkgs, lib, ... }:

{
  services = {
    # Enable the OpenSSH daemon
    openssh.enable = true;

    # Bluetooth manager (or use bluetoothctl, but this has a nice applet)
    blueman.enable = true;

    gnome = {
      gnome-keyring.enable = true;
    };

    postgresql = {
      enable = true;
    };
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "curses";
    };
    nm-applet.enable = true;
  };
}
