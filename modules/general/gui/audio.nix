{ config, lib, ... }:

let cfg = config.shincraft.gui;
in
with lib;
with types;

{
  config = mkIf cfg.enable
  (mkMerge [
    (mkIf cfg.audio.pipewire.enable
       {
         sound.enable = false;
         security.rtkit.enable = true;
         services.pipewire = {
           enable = true;
           alsa.enable = true;
           alsa.support32Bit = true;
           pulse.enable = true;
           wireplumber.enable = true;
         };
       }
    )

    (mkIf (!cfg.audio.pipewire.enable)
      {
        sound.enable = true;
        hardware.pulseaudio = {
          enable = true;
          daemon.config.flat-volumes = "no";
          extraConfig = "load-module module-switch-on-connect";
        };
      }
    )
  ]);
}
