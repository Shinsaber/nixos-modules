{ lib, stdenv, openjdk7, maven-3-8-4 ? null }:

stdenv.mkDerivation {
  pname = "java7-helper";
  version = "1.0.0";

  src = ./.;

  buildInputs = [ openjdk7 ] ++ lib.optional (maven-3-8-4 != null) maven-3-8-4;

  installPhase = ''
    mkdir -p $out/bin

    # Crée le script d'environnement Java 7
    substitute ${./java7-env.sh.in} $out/bin/java7-env.sh \
      --replace "@openjdk7@" "${openjdk7}"
    
    chmod +x $out/bin/java7-env.sh

    ${lib.optionalString (maven-3-8-4 != null) ''
    # Crée le script d'environnement Java 7 + Maven 3.8.4
    substitute ${./java7-maven-env.sh.in} $out/bin/java7-maven-env.sh \
      --replace "@openjdk7@" "${openjdk7}" \
      --replace "@maven384@" "${maven-3-8-4}"
    
    chmod +x $out/bin/java7-maven-env.sh
    ''}

    # Crée un wrapper pour java7
    cat > $out/bin/java7 <<EOF
#!/usr/bin/env bash
exec ${openjdk7}/bin/java "\$@"
EOF
    chmod +x $out/bin/java7

    # Crée un wrapper pour javac7
    cat > $out/bin/javac7 <<EOF
#!/usr/bin/env bash
exec ${openjdk7}/bin/javac "\$@"
EOF
    chmod +x $out/bin/javac7

    ${lib.optionalString (maven-3-8-4 != null) ''
    # Crée un wrapper pour maven avec Java 7
    cat > $out/bin/mvn7 <<EOF
#!/usr/bin/env bash
export JAVA_HOME=${openjdk7}
export M2_HOME=${maven-3-8-4}
export MAVEN_HOME=${maven-3-8-4}
exec ${maven-3-8-4}/bin/mvn "\$@"
EOF
    chmod +x $out/bin/mvn7
    ''}
  '';

  meta = with lib; {
    description = "Helper scripts for OpenJDK 7";
    longDescription = ''
      Scripts d'aide pour utiliser OpenJDK 7 de manière isolée
      sans affecter l'installation Java principale du système.
    '';
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
