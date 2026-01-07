{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };

  outputs = inputs@{ flake-parts, ... }:
  # https://flake.parts/module-arguments.html
  flake-parts.lib.mkFlake { inherit inputs; } (top@{ config, withSystem, moduleWithSystem, ... }: {
    imports = [
      # Optional: use external flake logic, e.g.
      # inputs.foo.flakeModules.default
      inputs.process-compose-flake.flakeModule
    ];
    flake = {
      # Put your original flake attributes here.
    };
    systems = [
      # systems for which you want to build the `perSystem` attributes
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
      # ...
    ];
    perSystem = { config, pkgs, ... }: {
      # Recommended: move all package definitions here.
      # e.g. (assuming you have a nixpkgs input)
      # packages.foo = pkgs.callPackage ./foo/package.nix { };
      # packages.bar = pkgs.callPackage ./bar/package.nix {
      #   foo = config.packages.foo;
      # };
      devShells.default = let dev = pkgs.writeShellScriptBin "dev" 
      ''
        nix run
      ''; 
      in pkgs.mkShell {
        buildInputs = [ pkgs.ruby pkgs.libyaml pkgs.watchman dev ];
      };

      process-compose.default = {
        imports = [
          inputs.services-flake.processComposeModules.default
        ];
        settings.processes = {
          tailwind_build.command = "bin/rails tailwindcss:build";

          css.command = "bin/rails tailwindcss:watch";
          css.is_tty = true;
          css.depends_on.tailwind_build.condition = "process_completed";

          setup.command = "bin/setup --skip-server";
          setup.depends_on.pg.condition = "process_healthy";

          server.command = "bin/dev";
          server.depends_on.setup.condition = "process_completed";
          server.depends_on.tailwind_build.condition = "process_completed";
        };

        services.postgres."pg" = {
          enable = true;
          package = pkgs.postgresql_16;

          port = 6666;
          # Postgres accepts hostnames/IPs here; using 127.0.0.1 avoids ipv6/localhost weirdness. :contentReference[oaicite:1]{index=1}
          listen_addresses = "127.0.0.1";

          initialDatabases = [
            { name = "speedpastes_development"; }
            { name = "speedpastes_test"; }
          ];
        };
      };
    };
  });

}