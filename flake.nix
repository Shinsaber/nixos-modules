{
  description = "shinsaber-nixos-modules";

  outputs = _: {
    nixosModules = {
      gui      = import ./modules/gui;
      splash   = import ./modules/splash;
      system   = import ./modules/system;
      terminal = import ./modules/terminal;
      tools    = import ./modules/tools;
      users    = import ./modules/users;
    };
  };
}