{
  description = "A plymouth theme with blur animation generated from user configured image";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.11";

  outputs = { self, nixpkgs }:
    let
      name = "citeos-vortex";
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      themeDir = ./src/citeos-vortex;
    in
    {
      packages.${system} = {
        ${name} = pkgs.callPackage
          (
            { stdenv
            }:

            stdenv.mkDerivation {
              pname = name;
              version = "0.1.0";

              src = themeDir;

              installPhase = ''
                runHook preInstall

                mkdir -p $out/share/plymouth/themes/${name}
                cp -r $src/* $out/share/plymouth/themes/${name}
                substituteInPlace $out/share/plymouth/themes/${name}/*.plymouth --replace '@IMAGES@' "$out/share/plymouth/themes/${name}"
                substituteInPlace $out/share/plymouth/themes/${name}/*.plymouth --replace '@SCRIPT@' "$out/share/plymouth/themes/${name}/${name}.script"

                runHook postInstall
              '';
            }
          )
          { };

        # sleep 1s ; plymouth ask-for-password --prompt=coucou ;
        preview = pkgs.writeShellScriptBin "preview" ''
          ${self.packages.${system}.testEnv}/bin/plymouthFHSEnv -c 'plymouthd --debug ; plymouth show-splash ; sleep 1s ; plymouth display-message --text="A que bonjour ÉéêâôÔ !" ; sleep 1s ; plymouth ask-for-password --prompt=coucou ; sleep 5s ; plymouth quit'
        '';

        testEnv = (pkgs.buildFHSEnv {
          name = "plymouthFHSEnv";
          targetPkgs = p: [
            self.packages.${system}.${name}
            (p.writeTextDir "etc/plymouth/plymouthd.conf" ''
              [Daemon]
              ShowDelay=0
              DeviceTimeout=8
              Theme=${name}
            '')
            (p.runCommand "build-plymouth-config-package" { } ''
              mkdir $out
              mkdir -p $out/etc/plymouth
              ln -s ${p.plymouth}/lib/plymouth $out/etc/plymouth/plugins
              ln -s ${self.packages.${system}.${name}}/share/plymouth/themes $out/etc/plymouth/themes
              ln -s ${p.plymouth}/share/plymouth/plymouthd.defaults $out/etc/plymouth/plymouthd.defaults
            '')
            p.plymouth
          ];
        });
      };
    }
  ;
}
