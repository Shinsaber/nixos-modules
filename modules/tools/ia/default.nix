{ config, lib, ... }:
let
  cfg = config.custom.tools.ia;
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