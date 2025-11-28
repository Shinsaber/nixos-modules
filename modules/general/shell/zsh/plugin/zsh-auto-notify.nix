{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "zsh-auto-notify";
  version = "0.11.1-private";

  src = fetchFromGitHub {
    owner = "philippdieter";
    repo = "zsh-auto-notify";
    rev = "${version}";
    sha256 = "sha256-oi5jb1/MQeEN/Iur3HBVIzcvd7oNZxBMzvFxW79jzAQ=";
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
    homepage = "https://github.com/philippdieter/zsh-auto-notify";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}