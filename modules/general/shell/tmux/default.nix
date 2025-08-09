{ config, lib, pkgs, ... }:
let
  cfg = config.shincraft.shell;
  tmux_conf       = builtins.readFile ./tmux.conf;
  catppuccin_conf = builtins.readFile ./catppuccin.conf;
  tmux-kubectx    = pkgs.callPackage ./plugin/tmux-kubectx.nix { };
in
with lib;
{
  config = mkMerge [
    (mkIf cfg.tmux.enable {
      programs.tmux = {
        enable = true;
        clock24 = true;
        extraConfig = with pkgs; mkMerge [
          ''
            set -ogq "@catppuccin_window_text" " #W"
            set -ogq "@catppuccin_window_current_text" " #W"
            set -g @catppuccin_status_left_separator "█"
            set -ogq "@catppuccin_kube_text" \
               " #{l:#[fg=#{@catppuccin_kube_context_color}]#{kubectx_context}#[fg=default]:#[fg=#{@catppuccin_kube_namespace_color}]#{kubectx_namespace}}"
            run-shell ${tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux
          ''
          catppuccin_conf
          ''
            #run-shell ${tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux
            run-shell ${tmuxPlugins.battery}/share/tmux-plugins/battery/battery.tmux
            run-shell ${tmuxPlugins.weather}/share/tmux-plugins/weather/tmux-weather.tmux
            run-shell ${tmux-kubectx}/share/tmux-plugins/tmux-kubectx/kubectx.tmux
          ''
          tmux_conf
        ];
      };
    })
  ];
}
