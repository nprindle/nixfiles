{ nlib }:

{ self
, nixpkgs
, nixos-hardware
, nur
, home-manager
, ...
}@inputs:

let
  mergeAttrs = builtins.foldl' (x: y: x // y) { };
in

nixpkgs.lib.nixosSystem rec {
  system = "x86_64-linux";
  modules =
    let
      # extra args to pass to imported modules
      args = {
        inherit inputs;
        custom = {
          pkgs = mergeAttrs [
            self.legacyPackages.${system}
            self.packages.${system}
          ];
          inherit (self) hmModules;
          inherit (self) lib;
        };
      };
      # modules for configuring hecate hardware
      hardwareModules = with nixos-hardware.nixosModules; [
        common-pc-laptop
        common-pc-laptop-ssd
        common-cpu-amd
        common-gpu-nvidia
        # configure the bus IDs for common-gpu-nvidia
        {
          hardware.nvidia.prime = {
            intelBusId = "PCI:5:0:0";
            nvidiaBusId = "PCI:1:0:0";
          };
        }
        # Auto-generated hardware configuration
        ./hardware-configuration.nix
      ];
      # the main configuration
      mainModule = import ./configuration.nix;
      # extra overlays from the inputs
      addOverlays = {
        nixpkgs.overlays = [
          nur.overlay
          self.overlays.fix-h-warning
        ];
      };
      # extra modules from the inputs
      otherModules = [
        home-manager.nixosModules.home-manager
      ];
    in
    nixpkgs.lib.flatten [
      nlib.flakes.useFlakes
      (nlib.flakes.pinFlakes { inherit nixpkgs; })

      (nlib.flakes.passArgs args)

      hardwareModules
      mainModule
      addOverlays
      otherModules
    ];
}
