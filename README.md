# 🚀 Dashboard

> [!NOTE]
> This project is a part of [SnapCore](https://github.com/SnapSettle/snapcore)!

**Dashboard** is a lightweight, NixOS-native service dashboard. It automatically scans your system configuration to discover enabled services and their assigned ports, presenting them in a clean, modern web interface.

No more manual bookmarking or hardcoding links—if it's enabled in your NixOS config, Dashboard finds it.

---

## ✨ Features

- **🔍 Zero-Hardcode Discovery**: Scans `config.services` and `options.services` to find active ports (supporting `.port`, `.settings.port`, `.listenPort`, and more).
- **🛠 Customizable Watchlist**: Define exactly which services to monitor via the `watchedServices` option.
- **🖼 Intelligent Icons**: Automatically fetches `favicon.ico` from services. Includes specific fallback logic for apps like **Bazarr** that hide icons in non-standard paths.
- **🛡 Firewall Integration**: Built-in `openFirewall` toggle to handle access automatically.
- **🎨 Modern UI**: A responsive, dark-themed grid layout that looks great on desktop and mobile.

---

## 📦 Installation

### Option A: Using Flakes (Recommended)

Add Dashboard to your `flake.nix` as a source input:

```nix
inputs = {
  dashboard-src = {
    url = "github:snapsettle/dashboard";
    flake = false;
  };
};

# In your outputs:
modules = [
  "${inputs.dashboard-src}/dashboard.nix"
];
```

OR

```nix
{
  inputs.dashboard.url = "github:snapsettle/dashboard";

  outputs = { self, nixpkgs, dashboard, ... }@inputs: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        dashboard.nixosModules.default
        ({ ... }: {
          services.dashboard = {
            enable = true;
            openFirewall = true; # Optional: opens the dashboard port
            watchedServices = [ "jellyfin" "sonarr" "radarr" "bazarr" "qbittorrent" ];
          };
        })
      ];
    };
  };
}
```

### Option B: Without Flakes (Traditional NixOS)

You can import the module directly from GitHub using `fetchTarball` in your `configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    (builtins.fetchTarball {
      url = "https://github.com/your-username/Dashboard/archive/master.tar.gz";
    } + "/Dashboard.nix")
  ];
}
```

---

## ⚙️ Configuration

Configure the dashboard directly in your NixOS configuration files:

```nix
services.dashboard = {
  enable = true;
  port = 8081;             # Access the dash at http://your-ip:8081
  openFirewall = true;     # Automatically open the port in the firewall

  # Services to monitor (only shown if they are also enabled in your config)
  watchedServices = [
    "jellyfin"
    "transmission"
    "radarr"
    "sonarr"
    "bazarr"
    "prowlarr"
    "home-assistant"
    "uptime-kuma"
  ];
};
```

---

## 🧠 How it Works

### 1. The Scavenger Logic

NixOS modules often store ports in different places. Dashboard intelligently probes the following paths for every service in your `watchedServices` list:

- Standard: `services.<name>.port`
- Submodules: `services.<name>.settings.port`
- Arr-Suite: `services.<name>.settings.server.port`
- Legacy/Specific: `portNumber` or `listenPort`

### 2. Static Site Generation

Dashboard uses `pkgs.writeText` to generate a static HTML/JavaScript dashboard at build time. This means the dashboard itself is incredibly fast and has zero runtime dependencies other than Nginx.

### 3. Client-Side Asset Discovery

Because some apps return a 404 or a redirect when hitting `/favicon.ico`, the dashboard includes a JavaScript fallback loop. It attempts to locate the icon across several common directory structures (e.g., `/static/images/`) before falling back to a clean placeholder icon.

---

## 🛠 Advanced Usage

If you have a service that uses a non-standard NixOS module where the port is not exposed to the options tree, simply define the port explicitly in your config, and Dashboard will pick it up:

```nix
# Example: If a module uses an 'extraConfig' string instead of a port option
services.my-custom-app.port = 9000;
```

---

_Built with ❄️ for the NixOS community._
