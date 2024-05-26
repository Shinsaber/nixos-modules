{ stdenv, autoPatchelfHook, fetchurl, ... }:

stdenv.mkDerivation rec {
  name = "markdown-preview-nvim-bin";
  version = "0.0.9";

  src = fetchurl {
    url = "https://github.com/iamcco/markdown-preview.nvim/releases/download/v${version}/markdown-preview-linux.tar.gz";
    sha256 = "9faf65a815d377d009149480b80509a439d3f623011b7be694e268dd220bad65";
  };


  
  unpackPhase = ''
    tar -xzvf $src
  '';

  installPhase = ''
    install -m755 -D markdown-preview-linux $out/bin/markdown-preview-linux
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    stdenv.cc.cc.lib
  ];
}
