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

  indexHtml = pkgs.writeText "index.html" ''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Dashnix</title>

        <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><circle cx=%2250%22 cy=%2250%22 r=%2245%22 fill=%22none%22 stroke=%22%23${accentColor}%22 stroke-width=%225%22/><path d=%22M50 20 L50 35 M80 50 L65 50 M50 80 L50 65 M20 50 L35 50%22 stroke=%22%23${accentColor}%22 stroke-width=%226%22 stroke-linecap=%22round%22/><path d=%22M50 50 L75 30%22 stroke=%22%23${textColor}%22 stroke-width=%228%22 stroke-linecap=%22round%22/></svg>">

        <style>
            :root {
                --accent: #${accentColor};
                --bg: #${bgColor};
                --card-bg: #${cardColor};
                --text: #${textColor};

                --glass-border: rgba(255, 255, 255, 0.12);
                --hover-border: #${accentColor};

                --shadow:
                    0 10px 30px rgba(0, 0, 0, 0.4),
                    0 2px 8px rgba(0, 0, 0, 0.3);

                --radius: 24px;
            }

            * {
                box-sizing: border-box;
            }

            html {
                min-height: 100%;
                background:
                    radial-gradient(circle at 15% 15%, #${accentColor}33 0%, transparent 40%),
                    radial-gradient(circle at 85% 85%, #${accentColor}15 0%, transparent 45%),
                    linear-gradient(180deg, #${bgColor} 0%, #000 130%);
                background-attachment: fixed;
            }

            body {
                margin: 0;
                min-height: 100vh;

                font-family: Inter, ui-sans-serif, system-ui, sans-serif;
                color: var(--text);

                padding: 4rem 2rem;
                overflow-x: hidden;
                position: relative;
            }

            body::before,
            body::after {
                content: "";
                position: fixed;

                width: 45rem;
                height: 45rem;

                border-radius: 999px;
                filter: blur(120px);

                opacity: 0.22;

                pointer-events: none;
                z-index: 0;
            }

            body::before {
                background: #${accentColor};
                top: -12rem;
                left: -12rem;
            }

            body::after {
                background: #${accentColor};
                bottom: -22rem;
                right: -12rem;
            }

            .container {
                max-width: 1350px;
                margin: 0 auto;
                position: relative;
                z-index: 1;
            }

            header {
                display: flex;
                align-items: center;
                gap: 1.25rem;
                margin-bottom: 3.5rem;
            }

            .logo {
                width: 58px;
                height: 58px;

                border-radius: 18px;

                background: linear-gradient(
                    145deg,
                    rgba(255, 255, 255, 0.15),
                    rgba(255, 255, 255, 0.03)
                );

                border: 1px solid var(--glass-border);

                display: flex;
                align-items: center;
                justify-content: center;

                backdrop-filter: blur(20px);
                box-shadow: var(--shadow);
            }

            h1 {
                margin: 0;

                font-size: clamp(2rem, 4vw, 3.5rem);
                font-weight: 800;

                letter-spacing: -0.04em;
                background: linear-gradient(135deg, var(--text) 60%, var(--accent));
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
            }

            .subtitle {
                opacity: 0.85;
                margin-top: 0.35rem;
                font-size: 0.95rem;
                letter-spacing: 0.02em;
            }

            .grid {
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
                gap: 1.5rem;
            }

            .card {
                position: relative;
                padding: 1.5rem;
                border-radius: var(--radius);

                background: linear-gradient(
                    165deg,
                    rgba(255, 255, 255, 0.09) 0%,
                    rgba(255, 255, 255, 0.02) 100%
                ), var(--card-bg);

                border: 1px solid var(--glass-border);

                backdrop-filter: blur(22px);

                text-decoration: none;
                color: inherit;
                overflow: hidden;

                transition:
                    transform 0.25s cubic-bezier(0.16, 1, 0.3, 1),
                    border-color 0.25s ease,
                    box-shadow 0.25s ease;

                box-shadow: var(--shadow);

                min-height: 220px;

                display: flex;
                flex-direction: column;
                justify-content: space-between;
            }

            /* Mouse-following hover glow border overlay */
            .card::before {
                content: "";
                position: absolute;
                inset: 0;
                border-radius: inherit;
                padding: 1px; /* Border thickness */
                background: radial-gradient(
                    250px circle at var(--hover-x, 50%) var(--hover-y, 50%),
                    var(--hover-border),
                    transparent 80%
                );
                -webkit-mask: 
                    linear-gradient(#fff 0 0) content-box, 
                    linear-gradient(#fff 0 0);
                -webkit-mask-composite: xor;
                mask-composite: exclude;
                opacity: 0;
                transition: opacity 0.3s ease;
                pointer-events: none;
            }

            .card:hover:not(.disabled)::before {
                opacity: 1;
            }

            .card:hover:not(.disabled) {
                transform: translateY(-6px) scale(1.015);
                border-color: transparent;

                box-shadow:
                    0 20px 35px rgba(0, 0, 0, 0.5),
                    0 0 25px #${accentColor}33;
            }

            .card:active:not(.disabled) {
                transform: scale(0.98);
            }

            .card.disabled {
                opacity: 0.45;
                filter: grayscale(0.6);
                cursor: not-allowed;
            }

            .status-badge {
                position: absolute;

                top: 16px;
                right: 16px;

                width: 12px;
                height: 12px;

                border-radius: 999px;
                background: #6b7280;
                border: 2px solid rgba(255, 255, 255, 0.15);

                z-index: 2;
            }

            .card.online .status-badge {
                background: #22c55e;
                box-shadow:
                    0 0 0 4px rgba(34, 197, 94, 0.2),
                    0 0 14px #22c55e;
            }

            .card.online .status-badge::after {
                content: "";
                position: absolute;
                inset: -4px;
                border-radius: inherit;
                border: 2px solid rgba(34, 197, 94, 0.5);
                animation: ping 2s infinite;
            }

            .card.offline .status-badge {
                background: #ef4444;
            }

            @keyframes ping {
                from {
                    opacity: 1;
                    transform: scale(0.8);
                }
                to {
                    opacity: 0;
                    transform: scale(1.8);
                }
            }

            .icon-wrapper {
                width: 52px;
                height: 52px;
                border-radius: 16px;

                background: linear-gradient(
                    145deg,
                    rgba(255, 255, 255, 0.18),
                    rgba(255, 255, 255, 0.04)
                );

                border: 1px solid rgba(255, 255, 255, 0.15);

                display: flex;
                align-items: center;
                justify-content: center;

                backdrop-filter: blur(16px);

                box-shadow:
                    inset 0 1px 1px rgba(255, 255, 255, 0.25),
                    0 6px 14px rgba(0, 0, 0, 0.25);

                position: relative;
                overflow: hidden;
            }

            .icon-wrapper::before {
                content: "";
                position: absolute;
                top: -40%;
                left: -20%;
                width: 140%;
                height: 70%;

                background: linear-gradient(
                    to bottom,
                    rgba(255, 255, 255, 0.25),
                    transparent
                );

                transform: rotate(-8deg);
            }

            .icon {
                width: 28px;
                height: 28px;

                object-fit: contain;
                position: relative;
                z-index: 1;

                filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
            }

            .card-content {
                display: flex;
                flex-direction: column;
                gap: 0.35rem;
            }

            h3 {
                margin: 0;
                font-size: 1.15rem;
                font-weight: 700;

                text-transform: capitalize;
                letter-spacing: -0.02em;
            }

            .card-subtitle {
                font-size: 0.88rem;
                opacity: 0.7;
            }

            @media (max-width: 640px) {
                body {
                    padding: 2rem 1rem;
                }

                .grid {
                    grid-template-columns: repeat(auto-fill, minmax(170px, 1fr));
                    gap: 1rem;
                }

                .card {
                    min-height: 190px;
                }
            }
        </style>
    </head>

    <body>
        <div class="container">

            <header>
                <div class="logo">
                    <svg width="30" height="30" viewBox="0 0 100 100">
                        <circle
                            cx="50"
                            cy="50"
                            r="45"
                            fill="none"
                            stroke="var(--accent)"
                            stroke-width="5"
                        />

                        <path
                            d="M50 20 L50 35 M80 50 L65 50 M50 80 L50 65 M20 50 L35 50"
                            stroke="var(--accent)"
                            stroke-width="6"
                            stroke-linecap="round"
                        />

                        <path
                            d="M50 50 L75 30"
                            stroke="var(--text)"
                            stroke-width="8"
                            stroke-linecap="round"
                        />
                    </svg>
                </div>

                <div>
                    <h1>Dashnix</h1>

                    <div class="subtitle">
                        Your homelab constellation
                    </div>
                </div>
            </header>

            <div id="grid" class="grid"></div>

        </div>

        <script>
            const services = ${jsonServices};
            const grid = document.getElementById('grid');
            const host = window.location.hostname;

            services.forEach(s => {
                const url = `http://''${host}:''${s.port}`;

                const card = document.createElement('a');

                card.className = 'card';
                card.href = url;

                card.innerHTML = `
                    <div class="status-badge"></div>

                    <div class="icon-wrapper">
                        <img
                            class="icon"
                            src="''${url}''${s.favicon}"
                            alt="''${s.name} favicon"
                            id="img-''${s.name}"
                        >
                    </div>

                    <div class="card-content">
                        <h3>''${s.name}</h3>

                        <div class="card-subtitle">
                            localhost:''${s.port}
                        </div>
                    </div>
                `;

                grid.appendChild(card);

                const img = document.getElementById(`img-''${s.name}`);

                img.onload = () => {
                    card.classList.add('online');
                };

                img.onerror = () => {
                    handleOffline(card, img);
                };

                function handleOffline(c, i) {
                    c.classList.add('disabled', 'offline');
                    c.onclick = (e) => e.preventDefault();
                    i.style.display = 'none';

                    i.parentElement.innerHTML = `
                        <svg
                            width="24"  /* Reduced from 34 */
                            height="24" /* Reduced from 34 */
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            opacity="0.7"
                        >
                            <path d="M18 6L6 18"/>
                            <path d="M6 6l12 12"/>
                        </svg>
                    `;
                }
            });

            document.querySelectorAll('.card').forEach(card => {
                card.addEventListener('mousemove', e => {
                    const rect = card.getBoundingClientRect();
                    card.style.setProperty('--hover-x', `''${e.clientX - rect.left}px`);
                    card.style.setProperty('--hover-y', `''${e.clientY - rect.top}px`);
                });
            });
        </script>
    </body>
    </html>
  '';

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
