{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "zsh-auto-notify";
  version = "0.8.1";

  src = fetchFromGitHub {
    owner = "MichaelAquilina";
    repo = "zsh-auto-notify";
    rev = "${version}";
    sha256 = "sha256-4PH7g7OY5hASgq4xdswYaCDnys4pz/wyIVkGgaPcgBI=";
  };

  dontConfigure = true;
  strictDeps    = true;
  dontUnpack    = true;
  dontBuild     = true;

  installPhase = ''
    install -Dm0444 $src/auto-notify.plugin.zsh --target-directory=$out/share/zsh/plugins/auto-notify
  '';

  meta = with lib; {
    description = "Plugin that automatically sends out a notification when a long running task has completed.";
    homepage = "https://github.com/MichaelAquilina/zsh-auto-notify";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}