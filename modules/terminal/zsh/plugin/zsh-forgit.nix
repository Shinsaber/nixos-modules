{ lib, stdenvNoCC, fetchFromGitHub, makeWrapper
, bash, coreutils, findutils, fzf, git, gnugrep, gnused, difftastic, delta }:

stdenvNoCC.mkDerivation rec {
  pname = "zsh-forgit";
  version = "23.09.0";

  src = fetchFromGitHub {
    owner = "wfxr";
    repo = "forgit";
    rev = version;
    sha256 = "sha256-WvJxjEzF3vi+YPVSH3QdDyp3oxNypMoB71TAJ7D8hOQ=";
  };

  dontConfigure = true;
  strictDeps    = true;
  dontUnpack    = true;
  dontBuild     = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -D $src/bin/git-forgit --target-directory=$out/share/zsh/plugins/forgit/bin/
    install -D $src/completions/_git-forgit --target-directory=$out/share/zsh/plugins/forgit/completions/_git-forgit
    install -D $src/completions/git-forgit.zsh --target-directory=$out/share/zsh/plugins/forgit/completions/git-forgit.zsh
    install -Dm0444 $src/forgit.plugin.zsh --target-directory=$out/share/zsh/plugins/forgit
    wrapProgram $out/share/zsh/plugins/forgit/bin/git-forgit \
      --prefix PATH : ${lib.makeBinPath [ bash coreutils findutils fzf git gnugrep gnused difftastic delta ]}
    substituteInPlace $out/share/zsh/plugins/forgit/forgit.plugin.zsh \
      --replace "\$INSTALL_DIR/bin/git-forgit" "$out/share/zsh/plugins/forgit/bin/git-forgit"
  '';

  meta = with lib; {
    homepage = "https://github.com/wfxr/forgit";
    description = "A utility tool powered by fzf for using git interactively";
    license = licenses.mit;
    maintainers = with maintainers; [ deejayem ];
    platforms = platforms.all;
  };
}