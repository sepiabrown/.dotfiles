{ config, pkgs, inputs, ... }:

{
  # system.copySystemConfiguration = true;  # not working with flakes?

  imports =
    [
      # Include the results of the hardware scan.
      #./crd/chrome-remote-desktop.nix
    ];

  #(environment.variables = {
  #  QT_IM_MODULE = "zoom";
  #};)

  environment.systemPackages = with pkgs; [
    # test
    #ponysay
    #cowsay

    # network/bluetooth/printer
    protonvpn-gui # run protonvpn-cli by nix run nixpkgs#protovpn-cli
    blueman
    #teamviewer
    #anydesk
    #hplipWithPlugin
    #(steam.override { withJava = true; extraPkgs = pkgs: [ mono gtk3 gtk3-x11 libgdiplus zlib glxinfo ]; nativeOnly = true; }).run # for hp-setup? after rebuild, do $ steam-run hp-setup

    # apps
    #firefox : moved to configuration_basic

    # etc
    zoom-us
  ];

  # List services that you want to enable:
  services = with pkgs; {
    # https://nixos.org/manual/nixos/stable/#sec-modularity, but doesn't need pkgs.lib.mkForce.. maybe not yet!
    tailscale.enable = true;
    openssh.openFirewall = false;
    xrdp = {
      enable = true;
      defaultWindowManager = "startplasma-x11";
    };
    #chrome-remote-desktop = {
    #  enable = true;
    #  user = "sepiabrown";
      # newSession = true;
      # xrandr --output eDP-1 --brightness 1 -> default
      # xrandr --output eDP-1 --brightness 0.01 -> 0.01 times brighter than default
    #};
    teamviewer.enable = true;
    printing = {
      enable = true;
      browsing = true;
      defaultShared = true;
      drivers = [ hplipWithPlugin ];
    };
    avahi = {
      enable = true;
      publish = {
        enable = true;
        userServices = true;
      };
      nssmdns = true;
    };
  };

  nixpkgs.overlays =
    let
      kimelib = pkgs.fetchurl {
        #url = "https://github.com/Riey/kime/releases/download/v${pkgs.kime.version}/libkime-qt-${pkgs.qt5.qtbase.version}.so";
        url = "https://github.com/Riey/kime/releases/download/v2.5.6/libkime-qt-5.9.5.so";
        #sha256 = "c7b9661272e58b1e47005ce7524ba42ba5e9da14ca027e775347af148c503ddd";
        #url = "https://github.com/sepiabrown/kime/releases/download/v2.5.7/libkime-qt-5.12.9.so";

        #sha256 = "sha256-x7lmEnLlix5HAFznUkukK6Xp2hTKAn53U0evFIxQPd0="; # 5.12.8.so
        #sha256 = "sha256-dSVTyomLiLYhLR8/SOI9QcfAFNgxu/GvKYrslCzwArE="; # 5.12.8.so
        sha256 = "sha256-g5YwZR55DFHlpickMhCSUIzCMM7YWvdSqGvgo/wByDk="; # 5.12.8.so
      };
    in
    [
      #(final: prev: {
      #  kime = prev.kime.override {
      #    qt5 = prev.qt512;
      #  };
      #})
      (final: prev: {
        zoom-us = prev.zoom-us.overrideAttrs (old: {
          #postFixup = old.postFixup + ''
          #  substituteInPlace $out/share/applications/Zoom.desktop --replace "Exec=" "Exec=env QT_IM_MODULE=kime "
          #'';
          postInstall = ''
            install -Dm755 ${kimelib} $out/opt/zoom/platforminputcontexts/libkimeplatforminputcontextplugin.so
          ''; # install -Dm755 ${pkgs.kime.outPath}/lib/qt-5.15.3/plugins/platforminputcontexts/libkimeplatforminputcontextplugin.so $out/opt/zoom/platforminputcontexts/
        });
      })
    ];

  fonts = {
    enableDefaultFonts = true;
    enableGhostscriptFonts = true;
    fontDir.enable = true;
    fontDir.decompressFonts = true;
  };

  networking.firewall = {
    allowedUDPPorts = [ 41641 631 ];
    allowedTCPPorts = [ 3389 631 ];
    checkReversePath = "loose"; # warning: Strict reverse path filtering breaks Tailscale exit node use and some subnet routing setups. Consider setting `networking.firewall.checkReversePath` = 'loose'
  };

  virtualisation.virtualbox = {
    host = {
      enable = true;
      enableExtensionPack = true;
    };
    ## When NixOS is installed inside VirtualBox
    # guest.enable = true;
    # guest.x11 = true;
  };
  
  users.extraGroups.vboxusers.members = [ "sepiabrown" ];

  virtualisation.docker = {
    enable = true;
  };

  hardware.sane.enable = true;


  # Optional: To protect your nix-shell against garbage collection you also need to add these options to your Nix configuration.
  # On other systems with Nix add the following configuration to your /etc/nix/nix.conf
  nix = {
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };
}
