{
  description = "shinsaber-nixos-modules";

  outputs = _: {
    nixosModules = {
      general  = import ./modules/general;
      server   = import ./modules/server;
    };
  };
}