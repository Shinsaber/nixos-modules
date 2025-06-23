{ config, lib, pkgs, ... }:
let
  cfg = config.shincraft.tools.java7;
in
with lib;
{
  config = mkMerge [
    (mkIf cfg.enable {
      # Ajoute OpenJDK 7 et Maven 3.8.4 aux packages système
      environment.systemPackages = with pkgs; [
        openjdk7
        java7-helper
        maven-3-8-4
      ];

      # Variables d'environnement pour Java 7
      environment.variables = mkIf cfg.setAsDefault {
        JAVA_HOME = "${pkgs.openjdk7}";
        JDK_HOME = "${pkgs.openjdk7}";
      };

      # Avertissement dans les logs
      warnings = [
        ''
          OpenJDK 7 est activé. Cette version de Java est obsolète et contient 
          de nombreuses vulnérabilités de sécurité. Elle ne devrait être utilisée 
          que pour des applications legacy qui ne peuvent pas être mises à jour.
          
          Considérez la migration vers une version plus récente de Java dès que possible.
        ''
      ];
    })
  ];
}
