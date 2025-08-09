{
  lib,
  fetchFromGitHub,
  stdenv,
}:
let
  rtpPath = "share/tmux-plugins";

  addRtp =
    path: rtpFilePath: attrs: derivation:
    derivation
    // {
      rtp = "${derivation}/${path}/${rtpFilePath}";
    }
    // {
      overrideAttrs = f: mkTmuxPlugin (attrs // f attrs);
    };

  mkTmuxPlugin =
    a@{
      pluginName,
      rtpFilePath ? (builtins.replaceStrings [ "-" ] [ "_" ] pluginName) + ".tmux",
      namePrefix ? "tmuxplugin-",
      src,
      unpackPhase ? "",
      configurePhase ? ":",
      buildPhase ? ":",
      addonInfo ? null,
      preInstall ? "",
      postInstall ? "",
      path ? lib.getName pluginName,
      ...
    }:
    addRtp "${rtpPath}/${path}" rtpFilePath a (
      stdenv.mkDerivation (
        a
        // {
          pname = namePrefix + pluginName;

          inherit
            pluginName
            unpackPhase
            configurePhase
            buildPhase
            addonInfo
            preInstall
            postInstall
            ;

          installPhase = ''
            runHook preInstall

            target=$out/${rtpPath}/${path}
            mkdir -p $out/${rtpPath}
            cp -r . $target
            if [ -n "$addonInfo" ]; then
              echo "$addonInfo" > $target/addon-info.json
            fi

            runHook postInstall
          '';
        }
      )
    );

in
mkTmuxPlugin {
  pluginName = "tmux-kubectx";
  version = "unstable-2024-12-27";
  src = fetchFromGitHub {
    owner = "tony-sol";
    repo = "tmux-kubectx";
    rev = "f3b1d2e5963778ecc754518c6f55257c7785d3b2";
    sha256 = "sha256-tkAiDnQ0TM5n3s57pPSBotS23qWOIg1XtHFA7Zywhfw=";
  };
}