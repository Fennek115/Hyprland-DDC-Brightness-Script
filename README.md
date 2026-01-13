# Hyprland DDC/CI Brightness Control Script

A high-performance Bash script designed to control external monitor brightness via DDC/CI (`ddcutil`) on Hyprland and other Wayland compositors. 

This solution addresses the specific latency and "race condition" issues inherent to sending I2C commands rapidly via keyboard shortcuts.

## 🚀 Motivation

Controlling external monitors via DDC/CI is fundamentally different from controlling a laptop backlight. The I2C protocol is slow, and `ddcutil` commands are blocking. 

If you bind a standard `ddcutil` command to a brightness key and press it repeatedly:
1.  **Process Pile-up:** Multiple instances of `ddcutil` spawn and fight for control of the I2C bus.
2.  **Race Conditions:** The brightness value may "bounce" (go up, then down, then up) because read/write operations overlap.
3.  **UI Freeze:** The input thread may stall waiting for the hardware to respond.

**This script solves these problems by implementing:**
* **Atomic Locking (`flock`):** Uses a non-blocking lock file. If an adjustment is already in progress, subsequent key presses are ignored until the bus is free. This creates a natural "cooldown" feeling and prevents queue buildup.
* **Parallel Execution:** Adjusts multiple monitors simultaneously (backgrounding processes) rather than sequentially, halving the wait time.
* **Relative Step Logic:** Uses native `ddcutil` relative values (`+` or `-`) to avoid the overhead of reading the current value before writing.

## 📋 Prerequisites

Ensure you have the following installed on your Arch Linux (or other) system:

* **ddcutil**: The core tool for DDC/CI communication.
* **util-linux**: Provides the `flock` command (usually installed by default).
* **i2c-dev**: The kernel module must be loaded.

```bash
sudo pacman -S ddcutil
sudo modprobe i2c-dev
```
### User Permissions (Critical)

To run this without `sudo`, your user must have access to the I2C devices. Add your user to the `i2c` group (or `video`, depending on your configuration):

```bash
sudo usermod -aG i2c $USER
# You may need to reboot or re-login for this to take effect.
```

## ⚙️ Configuration

1.  **Identify your Monitor Buses:**
    Run the following command to find which I2C bus numbers your monitors use:

    ```bash
    sudo ddcutil detect
    ```

    *Look for lines like `/dev/i2c-2`. The bus number here is `2`.*

2.  **Edit the Script:**
    Open `brightness.sh` and update the `BUSES` variable at the top of the file to match your hardware:

    ```bash
    # Configuration
    BUSES="2 4"     # Replace with your specific bus numbers (space separated)
    STEP=10         # Percentage to increase/decrease per keypress
    ```

## 📦 Installation

1.  Clone this repository or download the script:

    ```bash
    git clone [https://github.com/Fennek115/hyprland-ddc-brightness.git](https://github.com/Fennek115/hyprland-ddc-brightness.git)
    cd hyprland-ddc-brightness
    ```

2.  Make the script executable:

    ```bash
    chmod +x brightness.sh
    ```

3.  Move it to your scripts folder (optional but recommended):

    ```bash
    mv brightness.sh ~/.config/hypr/scripts/
    ```

## ⌨️ Hyprland Integration

Add the following lines to your `hyprland.conf`.

**Note:** It is recommended to use `binde` (repeatable bind). This allows you to hold the key down. The script's locking mechanism will automatically regulate the speed, ensuring the hardware isn't overwhelmed.

```ini
# Brightness control via DDC/CI
binde = ,XF86MonBrightnessUp,   exec, ~/.config/hypr/scripts/brightness.sh up
binde = ,XF86MonBrightnessDown, exec, ~/.config/hypr/scripts/brightness.sh down
```

## 🛠️ Troubleshooting

**The script runs but nothing happens.**

  * Check if `ddcutil` works manually in your terminal: `ddcutil getvcp 10 --bus=YOUR_BUS`.
  * If it says "Permission denied", check the [User Permissions](### User Permissions (Critical)) section above.

**The brightness changes too slowly.**

  * Increase the `STEP` variable in the script (e.g., to `15` or `20`).

**The brightness "stutters" when holding the key.**

  * This is intentional behavior to prevent the I2C bus from crashing. The script drops input events that occur while the previous command is still processing.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```

### Recommendations on "Best Practices" for the Repository

Since you asked about best practices, here are three quick tips to make the repo look "professional" alongside this documentation:

1.  **Use Semantic Versioning (Tags):** When you upload it, you can create a "Release" on GitHub (e.g., `v1.0.0`). It shows you care about stability.
2.  **Shebang portability:** We used `#!/bin/bash`. This is standard.
3.  **Clean Code:** The indentation in the script I gave you is consistent (4 spaces or 2 spaces). Keep that consistency if you edit it later.

This documentation is written to be clear for beginners but detailed enough for advanced users to understand *why* you wrote the code the way you did.
```
