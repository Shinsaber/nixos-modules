{
  nixpkgs.overlays = [
    (
      final: prev:
        {
          # Override jellyfin-web with custom modifications
          jellyfin-web = prev.jellyfin-web.overrideAttrs (finalAttrs: previousAttrs: {
            installPhase = ''
              runHook preInstall

              # this is the important line
              sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script><script src=\"/InPlayerPreview/ClientScript\"></script></head>#" dist/index.html
              mkdir -p $out/share
              cp -a dist $out/share/jellyfin-web

              runHook postInstall
            '';
          });
          
          # Add OpenJDK 7 derivation
          openjdk7 = prev.callPackage ./java7/openjdk7.nix { };
          java7-helper = prev.callPackage ./java7/java7-helper.nix {
            openjdk7 = final.openjdk7;
            maven-3-8-4 = final.maven-3-8-4;
          };
          
          # Add Maven 3.8.4 for Java 7 compatibility
          maven-3-8-4 = prev.callPackage ./java7/maven-3.8.4.nix {
            openjdk7 = final.openjdk7;
          };

          freelens = prev.callPackage ./freelens.nix { };
        }
    )
  ];
}
