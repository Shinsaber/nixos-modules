{ config, lib, pkgs, ... }:
let
  cfg = config.shincraft.shell;
  tmux_conf = builtins.readFile ./tmux.conf;
in
with lib;
{
  config = mkMerge [
    (mkIf cfg.tmux.enable {
      programs.tmux = {
        enable = true;
        clock24 = true;
        extraConfig = with pkgs; mkMerge [
          tmux_conf
          ''
            run-shell ${tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux
            run-shell ${tmuxPlugins.battery}/share/tmux-plugins/battery/battery.tmux
            run-shell ${tmuxPlugins.weather}/share/tmux-plugins/weather/weather.tmux
            run-shell ${tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux
          ''
        ];
      };
    })
  ];
}
