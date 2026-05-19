# LoopSign x86 Intel Player

![LoopSign logo](LoopSign-logo.png)

This repository contains the runtime scripts and provisioning utilities for the LoopSign x86 Intel signage player.

The setup is designed for:

- Debian + Xfce
- Intel integrated graphics
- Firefox ESR kiosk mode
- unattended operation
- pre-provisioned appliance-style deployments

The system is intended to be installed once, imaged, and then preloaded onto x86 devices before shipping.

## Architecture

The player startup flow is intentionally simple:

```text
BIOS
→ Plymouth splash
→ LightDM
→ Xfce session
→ autorun.sh
→ loopsign.sh
→ Firefox ESR kiosk
```

The player automatically:

- generates a unique device hash
- launches Firefox in kiosk mode
- refreshes the browser when internet connectivity returns
- performs automatic repository updates from GitHub
- supports unattended daily reboot through cron

---

## Repository

```text
https://github.com/Loop24-AS/ls-x86intel
```

Default branch:

```text
prod
```

---

## Runtime Scripts

### autorun.sh

Main startup script launched automatically after login.

Responsibilities:

- wait for time synchronization
- update repository from GitHub
- self-update `autorun.sh` if changed
- install sudo cron definition
- generate device hash
- launch watchdog
- launch LoopSign kiosk

---

### loopsign.sh

Launches Firefox ESR in kiosk mode using the generated device hash.

Example playback URL:

```text
https://play.loopsign.eu/hash/ABC1234
```

---

### autorefresh.sh

Connectivity watchdog.

Responsibilities:

- detect internet loss
- show offline warning after grace period
- automatically refresh Firefox using `Ctrl+R` when connectivity returns

---

### hashgenerator.sh

Generates a stable device identifier.

Priority order:

1. Ethernet MAC address
2. `/etc/machine-id`
3. DMI product UUID
4. DMI product serial
5. DMI board serial
6. Disk serial

The selected value is hashed using SHA-256 and shortened before being written to:

```text
/home/loopsign/Desktop/.hash.txt
```

---

### define-sudo-crontab.sh

Installs the root cron configuration from:

```text
sudo-crontab.txt
```

Currently used for scheduled daily reboot.

---

## Provisioning Scripts

These scripts are intended to run once while preparing the image.

### loopsignsplash.sh

Installs and activates the custom Plymouth boot splash.

The script:

- installs the Plymouth theme
- copies splash assets
- sets the default Plymouth theme
- regenerates initramfs

Run manually:

```bash
sudo ./loopsignsplash.sh
```

---

## Dependencies

Install required packages:

```bash
sudo apt install \
    firefox-esr \
    git \
    curl \
    zenity \
    xdotool \
    unclutter \
    plymouth \
    plymouth-themes \
    xxd \
    cloud-guest-utils
```

---

## Automatic Startup

`loopsign-autorun.desktop` launches:

```text
/home/loopsign/autorun.sh
```

during Xfce session startup.

---

## Firefox

Firefox ESR is used in kiosk mode.

Current launch mode:

```bash
firefox-esr --kiosk --new-window URL
```

Firefox policies may be configured through:

```text
/usr/lib/firefox-esr/distribution/policies.json
```

---

## Display / Power Management

The player assumes:

- X11
- LightDM
- Xfce

Xfce power manager is intentionally removed.

Screen blanking and DPMS should instead be handled through dedicated system configuration.

---

## Logging

Logs:

```text
/tmp/autorun.log
/tmp/loopsign.log
/tmp/hashgenerator.log
/home/loopsign/autorefresh.log
```

---

## Image Philosophy

This project intentionally favors:

- deterministic startup
- appliance-style behavior
- minimal abstraction
- reproducible imaging
- unattended reliability

The player is designed to behave more like a dedicated embedded appliance than a traditional desktop Linux system.
