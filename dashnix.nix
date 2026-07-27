{ config
, lib
, pkgs
, options
, ...
}:

with lib;

let
  cfg = config.services.dashnix;

  accentColor = config.lib.stylix.colors.base0D or "38bdf8";
  bgColor = config.lib.stylix.colors.base00 or "0f172a";
  cardColor = config.lib.stylix.colors.base01 or "1e293b";
  textColor = config.lib.stylix.colors.base05 or "f8fafc";

  getService =
    name:
    let
      svcConfig = config.services.${name} or { };
      svcOptions = options.services.${name} or { };
      isEnabled = svcConfig.enable or false;

      findPort =
        path:
        let
          confVal = attrByPath path null svcConfig;
          opt = attrByPath path null svcOptions;
          optDefault = if opt ? default then opt.default else null;
        in
        if confVal != null then confVal else optDefault;

      detectedPort =
        let
          p = findPort [ "port" ];
          sp = findPort [
            "settings"
            "port"
          ];
          sP = findPort [
            "settings"
            "Port"
          ];
          ssp = findPort [
            "settings"
            "server"
            "port"
          ];
          np = findPort [ "portNumber" ];
          lp = findPort [ "listenPort" ];
          wp = findPort [ "webuiPort" ];
          wPc = findPort [ "webUiPort" ];
        in
        if p != null then
          p
        else if sp != null then
          sp
        else if sP != null then
          sP
        else if ssp != null then
          ssp
        else if np != null then
          np
        else if lp != null then
          lp
        else if wp != null then
          wp
        else if wPc != null then
          wPc
        else
          null;

      port =
        if detectedPort != null then
          detectedPort
        else if name == "jellyfin" then
          "8096"
        else if name == "qbittorrent" then
          "8080"
        else
          null;

      # Define specific paths for services that don't use standard /favicon.ico
      favicon =
        if name == "jellyfin" then
          "/web/favicon.bc8d51405ec040305a87.ico"
        else if name == "bazarr" then
          "/images/favicon.ico"
        else if name == "qbittorrent" then
          "/images/qbittorrent-tray.svg"
        else
          "/favicon.ico";

    in
    if isEnabled && port != null then
      {
        inherit name favicon;
        port = toString port;
      }
    else
      null;

  activeServices = filter (x: x != null) (map getService cfg.watchedServices);
  jsonServices = builtins.toJSON activeServices;

  indexHtml = pkgs.replaceVars ./index.html {
    servicesJson = jsonServices;
    accentColor = accentColor;
    bgColor = bgColor;
    cardColor = cardColor;
    textColor = textColor;
  };

in
{
  options.services.dashnix = {
    enable = mkEnableOption "Dashnix dashboard";

    port = mkOption {
      type = types.port;
      default = 8081;
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };

    watchedServices = mkOption {
      type = types.listOf types.str;
      default = [
        "jellyfin"
        "qbittorrent"
        "radarr"
        "sonarr"
        "bazarr"
      ];
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
    services.nginx = {
      enable = true;
      virtualHosts."dashnix.local" = {
        listen = [
          {
            addr = "0.0.0.0";
            port = cfg.port;
          }
        ];
        root = "${pkgs.runCommand "dashnix-root" { } "mkdir $out; cp ${indexHtml} $out/index.html"}";
      };
    };
  };
}
