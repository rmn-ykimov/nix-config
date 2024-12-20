{
  description = "nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {

      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.neovim
          pkgs.mkalias
          pkgs.ffmpeg
          
          pkgs.git
          pkgs.git-lfs
          
          pkgs.stow
          pkgs.starship
          pkgs.tmux
          pkgs.rar
          pkgs.ripgrep
          pkgs.postgresql
          
          pkgs.docker
          pkgs.docker-compose
         
          pkgs.python313
          pkgs.python312
          
          pkgs.djvu2pdf
         
          pkgs.scons
          pkgs.cmake
         
          pkgs.vulkan-tools
          
          pkgs.tree

          pkgs.vscode
          pkgs.google-chrome
          pkgs.obsidian
          pkgs.darktable
          pkgs.dbeaver-bin
          pkgs.zotero
          pkgs.lmstudio
          #pkgs.wireguard-tools
          pkgs.utm
        ];

        system.activationScripts.applications.text = let
          env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
            '';

        homebrew = {
          enable = true;
          casks = [
            "blender"
            "vlc"
            "godot-mono"
          ];
          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
        };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      nix.optimise.automatic = true;

      nix.gc = {
        automatic = true;
        options = "--delete-older-than 7d";
      };

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      system.defaults = {
        dock.autohide = true;
        };
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Romans-MacBook-Air
    darwinConfigurations."Romans-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [ 
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              # Apple Silicon Only
              enableRosetta = true;
              # User owning the Homebrew prefix
              user = "roman";
            };
          }
        ];
    };
  };
}