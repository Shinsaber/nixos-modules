{ config, lib, ... }:

let
  cfg = config.shincraft.system.sops;
in
with lib;
{
  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = mkIf (cfg.defaultSopsFile != null) cfg.defaultSopsFile;
      # Déchiffrement avec la clé SSH host (convertie en clé age), sans GPG
      age.sshKeyPaths    = mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
      gnupg.sshKeyPaths  = mkDefault [];
    };
  };
}
