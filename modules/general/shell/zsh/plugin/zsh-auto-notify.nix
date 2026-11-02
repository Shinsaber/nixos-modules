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

  # Ajoute à la fin du plugin l'envoi des notifications vers le terminal client (SSH)
  installPhase = ''
    mkdir -p $out/share/zsh/plugins/auto-notify
    cat $src/auto-notify.plugin.zsh ${./auto-notify-terminal.zsh} > $out/share/zsh/plugins/auto-notify/auto-notify.plugin.zsh
    chmod 0444 $out/share/zsh/plugins/auto-notify/auto-notify.plugin.zsh
  '';

  meta = with lib; {
    description = "Plugin that automatically sends out a notification when a long running task has completed.";
    homepage = "https://github.com/philippdieter/zsh-auto-notify";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}