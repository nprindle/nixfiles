{ ... }:

{
  services.redshift = {
    enable = true;
    executable = "/bin/redshift-gtk";
    brightness = {
      day = "1";
      night = "0.8";
    };
    temperature = {
      day = 6500;
      night = 3200;
    };
  };
}
