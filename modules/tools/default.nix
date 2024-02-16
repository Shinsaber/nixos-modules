{lib, ...}:
with lib;
{
  imports =
  [
    ./hack
    ./ia
  ];

  options.custom.tools = {
    hack.enable = mkEnableOption "Activate hacking tools set";
    ia.llama    = mkEnableOption "Activate hacking tools set";
  };
}
