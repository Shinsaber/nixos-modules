{ config, lib, pkgs, ... }:
let
  cfg = config.custom.tools.hack;
in
with lib;
{
  config = mkMerge [
    (mkIf cfg.enable {
      programs.wireshark.enable = true;
      environment.systemPackages = with pkgs; [
        glances
        nmap
        dig
      ];
    })
  ];
}
