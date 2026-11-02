# Tests d'évaluation des modules : `nix flake check` (ou `nix eval .#checks.x86_64-linux.<cas>`).
#
# Chaque cas est une configuration NixOS synthétique (tests/<cas>.nix) qui active des options
# que les hosts réels n'activent pas forcément, plus des vérifications sur la configuration
# obtenue. Rien n'est construit : seule l'évaluation (instanciation) du système est faite.
#
# À maintenir : toute option ajoutée, renommée ou retirée doit apparaître dans un cas.
{ self, nixos, system }:

let
  lib  = nixos.lib;
  pkgs = nixos.legacyPackages.${system};

  cases = {
    workstation = import ./workstation.nix;
    server      = import ./server.nix;
  };

  mkCheck = name: case:
    let
      sys = lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.general
          ./common.nix
          case.module
        ] ++ lib.optional (case.server or false) self.nixosModules.server;
      };
      results = case.checks { inherit (sys) config pkgs; inherit lib; };
      failed  = lib.filter (n: !results.${n}) (lib.attrNames results);
      # Force l'évaluation complète du système sans en faire une dépendance de build
      drvPath = builtins.unsafeDiscardStringContext sys.config.system.build.toplevel.drvPath;
    in
    if failed != [] then
      throw "tests/${name}.nix : vérifications en échec : ${lib.concatStringsSep ", " failed}"
    else
      pkgs.runCommand "shincraft-test-${name}" { passthru.nixosConfiguration = sys; } ''
        echo "${drvPath}" > $out
      '';
in
lib.mapAttrs mkCheck cases
