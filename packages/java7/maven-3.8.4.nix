{ lib
, stdenv
, fetchurl
, makeWrapper
, openjdk7
}:

stdenv.mkDerivation rec {
  pname = "apache-maven";
  version = "3.8.4";

  src = fetchurl {
    url = "mirror://apache/maven/maven-3/${version}/binaries/apache-maven-${version}-bin.tar.gz";
    sha256 = "sha256-LNycUZQnuyD9wlvvWpBjt5Dkq9kw57FLTp9IY9b58Tw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ openjdk7 ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r ./* $out/

    # Crée un wrapper qui utilise Java 7
    makeWrapper $out/bin/mvn $out/bin/mvn-java7 \
      --set JAVA_HOME "${openjdk7}" \
      --set M2_HOME "$out" \
      --prefix PATH : "${openjdk7}/bin"

    # Crée également un wrapper pour mvnDebug
    makeWrapper $out/bin/mvnDebug $out/bin/mvnDebug-java7 \
      --set JAVA_HOME "${openjdk7}" \
      --set M2_HOME "$out" \
      --prefix PATH : "${openjdk7}/bin"

    # Crée un script d'environnement pour Maven + Java 7
    cat > $out/bin/maven-java7-env <<EOF
#!/usr/bin/env bash
# Script d'environnement pour Maven 3.8.4 avec Java 7

export JAVA_HOME="${openjdk7}"
export M2_HOME="$out"
export MAVEN_HOME="$out"
export PATH="${openjdk7}/bin:$out/bin:\$PATH"

echo "Environment configuré pour Maven 3.8.4 avec Java 7"
echo "JAVA_HOME=\$JAVA_HOME"
echo "M2_HOME=\$M2_HOME"
echo "Version Java: \$(java -version 2>&1 | head -n1)"
echo "Version Maven: \$(mvn -version | head -n1)"

# Lance un shell avec l'environnement configuré
exec "\$@"
EOF
    chmod +x $out/bin/maven-java7-env

    runHook postInstall
  '';

  # Pas de fixup automatique pour éviter de modifier les scripts Maven
  dontPatchShebangs = true;

  meta = with lib; {
    description = "Apache Maven 3.8.4 configured for Java 7";
    longDescription = ''
      Apache Maven 3.8.4, la dernière version de Maven compatible avec Java 7.
      Les versions ultérieures de Maven (3.9+) nécessitent Java 8 ou plus récent.
      
      Cette version est spécialement configurée pour utiliser OpenJDK 7.
      
      AVERTISSEMENT: Java 7 et Maven 3.8.4 sont obsolètes et ne reçoivent 
      plus de mises à jour de sécurité. À utiliser uniquement pour des 
      projets legacy qui ne peuvent pas être mis à jour.
    '';
    homepage = "https://maven.apache.org/";
    license = licenses.asl20;
    platforms = platforms.unix;
    maintainers = [ ];
    knownVulnerabilities = [
      "Maven 3.8.4 is end-of-life and may contain security vulnerabilities"
      "Java 7 is end-of-life and contains many security vulnerabilities"
      "Use only for legacy projects that cannot be updated"
    ];
  };
}
