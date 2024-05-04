{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "zsh-autopair";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "hlissner";
    repo = "zsh-autopair";
    rev = "v${version}";
    sha256 = "1h0vm2dgrmb8i2pvsgis3lshc5b0ad846836m62y8h3rdb3zmpy1";
  };

  dontConfigure = true;
  strictDeps    = true;
  dontUnpack    = true;
  dontBuild     = true;

  installPhase = ''
    install -Dm0444 $src/autopair.zsh --target-directory=$out/share/zsh/plugins/autopair
    install -Dm0444 $src/autopair.plugin.zsh --target-directory=$out/share/zsh/plugins/autopair
  '';

  meta = with lib; {
    homepage = "https://github.com/hlissner/zsh-autopair";
    description = "A plugin that auto-closes, deletes and skips over matching delimiters in zsh intelligently";
    license = licenses.mit;
    platforms = platforms.all;
  };
}