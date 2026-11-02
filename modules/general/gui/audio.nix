{ config, lib, ... }:

let cfg = config.shincraft.gui;
in
with lib;

{
  # PipeWire remplace PulseAudio et ALSA en espace utilisateur
  config = mkIf (cfg.enable && cfg.audio.pipewire.enable) {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };
}
