{
  description = "Servant libraries";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: let

      compilerVersion = "8107";

      haskellOverlay = hnew: hold: with pkgs.haskell.lib; {
        servant              = self.callCabal2nix "servant"              ./servant              {};
        servant-docs         = self.callCabal2nix "servant-docs"         ./servant-docs         {};
        servant-pipes        = self.callCabal2nix "servant-pipes"        ./servant-pipes        {};
        servant-server       = self.callCabal2nix "servant-server"       ./servant-server       {};
        servant-client       = self.callCabal2nix "servant-client"       ./servant-client       {};
        servant-foreign      = self.callCabal2nix "servant-foreign"      ./servant-foreign      {};
        servant-conduit      = self.callCabal2nix "servant-conduit"      ./servant-conduit      {};
        servant-machines     = self.callCabal2nix "servant-machines"     ./servant-machines     {};
        servant-client-core  = self.callCabal2nix "servant-client-core"  ./servant-client-core  {};
        servant-http-streams = self.callCabal2nix "servant-http-streams" ./servant-http-streams {};
      };

      pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = false; allowBroken = true;};
        };

      hsPkgs = pkgs.haskell.packages."ghc${compilerVersion}";

      # modifier used in haskellPackages.developPackage
      myModifier = drv:
        pkgs.haskell.lib.addBuildTools drv (with hsPkgs;[
          cabal-install
          haskell-language-server
        ]);

      mkPackage = name:
          hsPkgs.developPackage {
            root =  pkgs.lib.cleanSource (builtins.toPath ../. + "/${name}");
            name = name;
            returnShellEnv = false;
            withHoogle = true;
            overrides = haskellOverlay;
            modifier = myModifier;
          };

    in {
      packages = {
        servant = self.packages.${system}."servant-${compilerVersion}";
        servant-8107 = mkPackage "servant";
      };

      defaultPackage = self.packages.${system}.servant;

      devShells = {
        servant = self.packages.${system}.servant;
      };
  });
}
