{
  description = "My haskell library";

  nixConfig = {
    substituters = [
      "https://haskell-language-server.cachix.org"
    ];
    trusted-public-keys = [
      "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    hls.url = "github:haskell/haskell-language-server";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, hls, ... }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let

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

        # ip = unmarkBroken (dontCheck hold.ip);
        # relude = hold.relude_1_0_0_1;
        # co-log-polysemy = doJailbreak (hold.co-log-polysemy);
        # netlink = (overrideSrc hold.netlink {
        #   version = "1.1.2.0";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "teto";
        #     repo = "netlink-hs";
        #     rev = "090a48ebdbc35171529c7db1bd420d227c19b76d";
        #     sha256 = "sha256-qopa1ED4Bqk185b1AXZ32BG2s80SHDSkCODyoZfnft0=";
        #   };
        # });
      };

      pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = false; allowBroken = true;};
        };

      hsPkgs = pkgs.haskell.packages."ghc${compilerVersion}";

      # modifier used in haskellPackages.developPackage
      myModifier = drv:
        pkgs.haskell.lib.addBuildTools drv (with hsPkgs; [
          cabal-install
          hls.packages.${system}."haskell-language-server-${compilerVersion}"
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
