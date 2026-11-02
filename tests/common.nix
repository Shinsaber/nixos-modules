# Socle commun des cas de test : ce qu'un host réel fournit toujours.
{ ... }:
{
  system.stateVersion = "26.05";
  nixpkgs.config.allowUnfree = true;

  # sops : un fichier vide suffit à l'évaluation, les secrets ne sont pas déchiffrés
  sops.validateSopsFiles = false;
  shincraft.system.sops = {
    enable          = true;
    defaultSopsFile = builtins.toFile "secrets.yaml" "";
  };
}
