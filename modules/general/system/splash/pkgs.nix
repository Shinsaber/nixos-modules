{
  pkgs  ? import <nixpkgs> {},
  theme ? "vortex",
  logo  ? ./nixos.png,
  name  ? "NixOS",
  colorNormal ? "Color(0.3600, 0.5200, 0.6700)",
  colorTinted ? "Color(0.2400, 0.3500, 0.5900)",
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
    cp ${logo} $out/share/plymouth/themes/${theme}/images/logo.png
    sed -i "s@\/usr\/@$out\/@" $out/share/plymouth/themes/${theme}/${theme}.plymouth
    sed -i "s@%name%@${name}@" $out/share/plymouth/themes/${theme}/${theme}.script
    sed -i "s@%colorNormal%@${colorNormal}@" $out/share/plymouth/themes/${theme}/${theme}.script
    sed -i "s@%colorTinted%@${colorTinted}@" $out/share/plymouth/themes/${theme}/${theme}.script
  '';
}
