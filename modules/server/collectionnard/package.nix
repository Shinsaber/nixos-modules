# Collectionnard construit depuis les sources d'une release (tag vX.Y.Z) :
#   server : binaire colec-server + migrations SQL (share/collectionnard/db/migrations)
#   web    : SPA Vue compilée par Vite (fichiers statiques servis par nginx)
#
# Mise à jour : changer `version`, puis remplacer les trois hashes par `lib.fakeHash` un par un
# et reprendre la valeur donnée par l'erreur de `nix build` (src, puis vendorHash, puis npmDepsHash).
{ lib, fetchFromGitHub, buildGoModule, buildNpmPackage, nodejs_22 }:

let
  version = "v0.5.0";

  src = fetchFromGitHub {
    owner = "Shinsaber";
    repo  = "collectionnard";
    rev   = "${version}";
    hash  = "sha256-Ltg5kutYUIHVfzNzdoE1IG37kQshhMN5STIlALEkhRU=";
  };

  meta = {
    description = "Gestion de collections générique (séries, livres, BD, vinyles…)";
    homepage    = "https://github.com/Shinsaber/collectionnard";
    license     = lib.licenses.mit;
  };
in
{
  server = buildGoModule {
    pname = "collectionnard-server";
    inherit version src;
    sourceRoot = "${src.name}/server";
    vendorHash = "sha256-kSBoXuv+Ffwwv8SNgNILN1QlFtcY1wHUIiQ6R3AMrew=";

    env.CGO_ENABLED = 0;
    ldflags = [ "-s" "-w" ];
    # Les tests d'intégration demandent une base PostgreSQL : la CI du projet les lance
    doCheck = false;

    postInstall = ''
      mv $out/bin/colec $out/bin/colec-server
      mkdir -p $out/share/collectionnard/db
      cp -r ../db/migrations $out/share/collectionnard/db/
    '';

    meta = meta // { mainProgram = "colec-server"; };
  };

  web = buildNpmPackage {
    pname = "collectionnard-web";
    inherit version src;
    sourceRoot  = "${src.name}/web";
    nodejs      = nodejs_22;
    npmDepsHash = "sha256-c8N/4MzQ0UMH2oIQIJmEkwT5LZnnB86W934Bj5BInJs=";

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';

    inherit meta;
  };
}
