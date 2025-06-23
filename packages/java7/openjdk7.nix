{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, zlib
, cups
, freetype
, alsa-lib
, libjpeg
, giflib
, libpng
, libX11
, libXt
, libXext
, libXrender
, libXtst
, libXi
, libXinerama
, libXcursor
, libXrandr
, fontconfig
}:

stdenv.mkDerivation {
  pname = "openjdk7";
  version = "7u80-b15";

  # Utilise Zulu OpenJDK 7 qui est une distribution fiable d'OpenJDK 7
  src = fetchurl {
    url = "https://cdn.azul.com/zulu/bin/zulu7.40.0.15-ca-jdk7.0.272-linux_x64.tar.gz";
    sha256 = "sha256-Xvv3IaQzWhnIw/vyzy/OjRxrSnZvuT6Y+TA4RfidkB4=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    cups
    freetype
    alsa-lib
    libjpeg
    giflib
    libpng
    libX11
    libXt
    libXext
    libXrender
    libXtst
    libXi
    libXinerama
    libXcursor
    libXrandr
    fontconfig
  ];

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out
    cp -r ./* $out/
    
    # Crée les liens symboliques nécessaires
    mkdir -p $out/nix-support
    
    # Configuration Java
    cat > $out/nix-support/setup-hook <<EOF
    if [ -z "\''${JAVA_HOME-}" ]; then
      export JAVA_HOME=$out
    fi
    
    if [[ ":\$PATH:" != *":$out/bin:"* ]]; then
      export PATH=$out/bin:\$PATH
    fi
    EOF
    
    runHook postInstall
  '';

  # Fix permissions
  postFixup = ''
    find $out -type f -executable -exec chmod +x {} \;
  '';

  meta = with lib; {
    description = "Zulu OpenJDK 7 - Java Development Kit";
    longDescription = ''
      Zulu OpenJDK 7, une distribution d'OpenJDK 7 maintenue par Azul Systems.
      Cette version est obsolète et non supportée officiellement par Oracle,
      à utiliser uniquement pour des applications legacy.
      
      AVERTISSEMENT: Java 7 contient de nombreuses vulnérabilités de sécurité
      et ne devrait pas être utilisé en production.
    '';
    homepage = "https://www.azul.com/downloads/zulu-community/";
    license = licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
    # Marque comme non supporté
    knownVulnerabilities = [
      "OpenJDK 7 is end-of-life and contains many security vulnerabilities"
      "Use only for legacy applications that cannot be updated"
    ];
  };
}
