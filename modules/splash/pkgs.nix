{
  pkgs ? import <nixpkgs> {},
  theme ? "citeos-vortex",
}:
pkgs.stdenv.mkDerivation {
  pname = "splash-boot";
  version = "0.1.0";

  src = ./src;

  buildInputs = [
  ];

  unpackPhase = ''
  '';

  configurePhase = ''
    mkdir -p $out/share/plymouth/themes/${theme}
  '';

  buildPhase = ''
  '';

  # Currently not multi-theme enabled
  installPhase = ''
    cd ${theme}
    cp -r images/ ${theme}.script ${theme}.plymouth $out/share/plymouth/themes/${theme}
    sed -i "s@\/usr\/@$out\/@" $out/share/plymouth/themes/${theme}/${theme}.plymouth
  '';
}
