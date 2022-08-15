{
  # Manual : https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-references
  description = "sepiabrown's awesome system config of doom";
  inputs = {
    #nixos_unstable.url = "github:sepiabrown/nixpkgs/nixos-unstable";
    #nixos_unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    #home-manager_unstable.url = "github:nix-community/home-manager";
    #home-manager_unstable.inputs.nixpkgs.follows = "nixos_unstable";
    #nixos_2105.url = "nixpkgs/nixos-21.05";
    nixpkgs.url = "github:sepiabrown/nixpkgs/chrome-remote-desktop_2205"; # for darwinConfigurations
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #nimf.url = "github:sepiabrown/nimf/NixOS_nimf";
    #pinpox.url = "github:pinpox/nixos";
    #nix-direnv.url = "github:nix-community/nix-direnv";
    #nixos_unstable.url = "github:nixos/nixpkgs/nixos-21.05";
    #nixos_unstable_fixed.url = "github:sepiabrown/nixpkgs/c3805ba16cf4a060cdbb82d4ce21b74f9989dbb8";
    flake-utils = {
      url = "github:numtide/flake-utils";
      #inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs: with inputs;
    let
      nixpkgs_config = {
        nixpkgs.config = {
          #allowUnfree = true;
          allowBroken = true;
          allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
            "corefonts"
            "hplip"
            "hplipWithPlugin"
            "dropbox"
            "zoom"
            "foxitreader"
            "vscode"
            "vscode-with-extensions"
            "vscode-extension-ms-vscode-remote-remote-ssh"
            "chrome-remote-desktop"
            "teamviewer"
            "Oracle_VM_VirtualBox_Extension_Pack"
            "lutris"
            "steam"
            "steam-original"
            "steam-runtime"
          ];
          #permittedInsecurePackages = [
          #  "xpdf-4.02"
          #];
        };
      };

      nixpkgs_overlays = {
        nixpkgs.overlays = [
          #(_: _: { nimf_flake = nimf.defaultPackage.${system}; })
          #(_: _: { hello_flake = pinpox.packages.${system}.hello-custom; })
          #(_: _: { filebrowser_flake = pinpox.packages.${system}.filebrowser; })
          # because home-manager uses nixpkgs nix-direnv which requires 'enableFlakes' argument,
          # 'enableFlakes' is built into home-manager's module config used by xdg submodule. 
          # It is nearly impossible to fix submodule config. mkForce, mkRemovedOptionModule 
          # can't erase config's 'enableFlakes'. However the nix-community version doesn't 
          # have argument for 'enableFlakes'.  Changing only version doesn't 
          # affect the file status. Change sha256 arbitrarily to update!
          (self: super: {
            nix-direnv = super.nix-direnv.overrideAttrs (old: rec {
              version = "ed4cb3f30654f2266b5ed9fd6354c2592765b014"; # 2.1.2 version with nix_direnv_watch_file
              src = super.fetchFromGitHub {
                owner = "sepiabrown";
                repo = "nix-direnv";
                rev = version;
                sha256 = "sha256-ho0f+GwgC6hiDp2prnKCZJcTnyGDrsAfyQIXHwQRcOw=";
              };
            });
          })
          #(_: _: { nix-direnv = nixos_unstable.legacyPackages.${system}.nix-direnv; })
          #(_: _: { protonvpn-gui_2105 = nixos_2105.legacyPackages.${system}.protonvpn-gui; })
        ];
      };
      # in
      # (flake-utils.lib.eachDefaultSystem (system:
      #   let
      pkgs = import nixpkgs {
        #inherit system;
        system = "x86_64-linux";
      };
      pkgs_darwin = import nixpkgs {
        #inherit system;
        system = "x86_64-darwin";
      };
      # lib = nixpkgs.lib;
      # maping devices: https://www.reddit.com/r/NixOS/comments/j4k2zz/does_anyone_use_flakes_to_manage_their_entire/
      targets = map (nixpkgs.lib.removeSuffix ".nix") (
        nixpkgs.lib.attrNames (
          nixpkgs.lib.filterAttrs
            (_: entryType: entryType == "regular")
            (builtins.readDir ./devices)
        )
      );
      build-target = target: {
        name = target;
        value = nixpkgs.lib.nixosSystem {
          #inherit system;
          system = "x86_64-linux";
          modules = [

            nixpkgs_config

            nixpkgs_overlays

            #({ pkgs, ... } : { environment.systemPackages = with pkgs; [ 
            #  #nimf_flake 
            #  #hello_flake 
            #  #filebrowser_flake 
            #  ];
            #})

            ./configuration_basic.nix
            ./configuration_optional.nix
            #./homemanager_basic.nix
            #./homemanager_optional.nix
            ./with_keyboard_fix.nix
            ./secret.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.sepiabrown.imports = [
                ./homemanager_basic.nix
                ./homemanager_optional.nix
              ] ++ nixpkgs.lib.optionals (builtins.pathExists (./devices + "/${target}/homemanager.nix")) [ # Every folder needs to be git added!

                (./devices + "/${target}/homemanager.nix")
              ];
            }
            (./devices + "/${target}.nix")
            (./devices + "/${target}/hardware-configuration.nix")
          ];
          specialArgs = { inherit inputs; };
        };
      };

      build-target_darwin = target: {
        name = target;
        value = darwin.lib.darwinSystem {
          #inherit system;
          system = "x86_64-darwin";
          modules = [

            nixpkgs_config

            nixpkgs_overlays

            #({ pkgs, ... } : { environment.systemPackages = with pkgs; [ 
            #  #nimf_flake 
            #  #hello_flake 
            #  #filebrowser_flake 
            #  ];
            #})

            #./configuration_basic.nix
            #./configuration_optional.nix
            #./homemanager_basic.nix
            #./homemanager_optional.nix
            #./with_keyboard_fix.nix
            ./secret_mac.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.bayeslab.imports = [
                ./homemanager_basic.nix
                ./homemanager_optional.nix
              ] ++ nixpkgs.lib.optionals (builtins.pathExists (./devices + "/${target}/homemanager.nix")) [ # Every folder needs to be git added!

                (./devices + "/${target}/homemanager.nix")
              ];
            }
            (./devices + "/${target}.nix")
            #(./devices + "/${target}/hardware-configuration.nix")
          ];
          specialArgs = { inherit inputs; };
        };
      };

    in
    {
      nixosConfigurations = builtins.listToAttrs (
        nixpkgs.lib.flatten (map (target: [ (build-target target) ]) targets)
      );

      darwinConfigurations = builtins.listToAttrs (
        nixpkgs.lib.flatten (map (target: [ (build-target_darwin target) ]) targets)
      );
      #})) // {
      homeConfigurations = {
        sepiabrown = home-manager.lib.homeManagerConfiguration rec {
          system = "x86_64-linux";
          #legpkgs = nixos_unstable_fixed.legacyPackages.x86_64-linux;#system;
          #pkgs = nixos.legacyPackages.x86_64-linux;
          pkgs = import nixpkgs {
            inherit system;
          };
          username = "sepiabrown";
          homeDirectory = if pkgs.stdenv.isLinux then "/home/sepiabrown" else if pkgs.stdenv.isDarwin then "/Users/bayeslab/SW" else "";
          configuration.imports = [
            ./homemanager_basic.nix
            ./homemanager_optional.nix
            nixpkgs_config

            nixpkgs_overlays
            #({...}:{
            #  home.file = {
            #    ".config/nix/nix.conf".text = ''
            #      experimental-features = nix-command flakes
            #      keep-derivations = true
            #      keep-outputs = true
            #    '';
            #  };
            #})
          ];
        };
      };
    };
  # nixosConfigurations = {
  #   sepiabrown-nix = lib.nixosSystem {
  #     inherit system;
  #     modules = [
  #       ./configuration_current.nix
  #       ./configuration_basic.nix
  #       ./with_keyboard_fix.nix
  #       ./configuration.nix
  #       ./hardware-configuration.nix
  #       ./secret.nix
  #       home-manager.nixosModules.home-manager {
  #         home-manager.useGlobalPkgs = true;
  #         home-manager.useUserPackages = true;
  #       }
  #     ];
  #   };
  # };
}
# Every folder needs to be git added!
#
