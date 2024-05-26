{ config, lib, ... }:
let
  cfg = config.shincraft.tools.ia;
in
with lib;
{
  config = mkMerge [
    (mkIf cfg.llama {
      #services.ollama.enable  = true;
      #services.ollama.package = pkgs.llama-cpp;
    })
  ];
}