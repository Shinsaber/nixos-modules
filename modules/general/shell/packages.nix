{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    lm_sensors
    pciutils
    usbutils
    htop
    tree
    eza
    ncdu
    unzip
    wget
    vim
    git
    jq
    delta
    bat
    sshfs
    nil
    nixpkgs-fmt
    restic
    daemontools
  ];
}