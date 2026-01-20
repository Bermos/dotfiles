# LCARS Enterprise-E Engineering Console

A Star Trek Enterprise-E inspired LCARS engineering console interface for [EWW](https://github.com/elkowar/eww) (ElKowars Wacky Widgets). Designed as an interactive desktop background for Hyprland with a 32:9 ultrawide monitor (5120x1440).

![LCARS Console Preview](preview.png)

## Features

- **Animated Warp Core**: Central visual centerpiece with dynamic color states
  - Blue-cyan glow at idle/low load
  - Brighter cyan-ice at medium load (40-70%)
  - Orange warning state (70-90%)
  - Red critical alert with pulsing animation (90%+)
  
- **Left Panel - Engineering Systems**:
  - CPU usage with total load indicator
  - Memory allocation (RAM + Swap)
  - Thermal readings (CPU/GPU temperatures)
  - Data transfer rates (Disk I/O)

- **Right Panel - Operations Status**:
  - Network interface status with live speeds
  - Upload/download rates
  - Active connections count
  - Storage arrays with vertical bar visualization

- **Top Panel - System Info**:
  - Vessel designation (hostname)
  - Stardate (current date)
  - Ship time (live clock)
  - Operational time (uptime)
  - Core version (kernel)
  - Active processes count

- **Bottom Panel - Quick Actions**:
  - Lock workstation
  - Standby (suspend)
  - Restart (reboot)
  - Shutdown (power off)

## Dependencies

### Required

```bash
# Arch Linux / Manjaro
sudo pacman -S eww-wayland

# If eww-wayland is not available, build from source:
# https://github.com/elkowar/eww

# Required for scripts
sudo pacman -S iproute2 procps-ng coreutils gawk
```

### Optional (for temperature monitoring)

```bash
# For better temperature readings
sudo pacman -S lm_sensors

# Run sensors-detect to configure
sudo sensors-detect
```

### Font

The interface uses JetBrainsMono Nerd Font. Install it:

```bash
# Arch Linux
sudo pacman -S ttf-jetbrains-mono-nerd

# Or download from:
# https://www.nerdfonts.com/font-downloads
```

## Installation

1. **Clone or copy the configuration**:
   ```bash
   # Create EWW config directory if it doesn't exist
   mkdir -p ~/.config/eww
   
   # Copy all files
   cp -r eww-lcars/* ~/.config/eww/
   ```

2. **Make scripts executable** (if not already):
   ```bash
   chmod +x ~/.config/eww/scripts/*.sh
   ```

3. **Test the scripts** (optional):
   ```bash
   # Test CPU monitoring
   ~/.config/eww/scripts/cpu.sh total
   
   # Test memory monitoring
   ~/.config/eww/scripts/memory.sh percent
   
   # Test network monitoring
   ~/.config/eww/scripts/network.sh interface
   ```

## Usage

### Launch the dashboard

```bash
# Start EWW daemon and open the LCARS console
eww daemon
eww open lcars-console

# Or in one command
eww open lcars-console
```

### Close the dashboard

```bash
eww close lcars-console
```

### Reload after changes

```bash
eww reload
```

### Check for errors

```bash
eww logs
```

## Hyprland Configuration

Add to your `~/.config/hypr/hyprland.conf`:

```conf
# EWW LCARS - Layer rules for desktop widget
layerrule = blur, eww-lcars
layerrule = ignorealpha 0.5, eww-lcars

# Optional: Start EWW on login
exec-once = eww daemon && eww open lcars-console
```

## Customization

### Color Palette

Edit the color variables at the top of `eww.scss`:

```scss
// Backgrounds
$bg-dark: rgba(15, 17, 23, 0.85);
$bg-glass: rgba(25, 30, 45, 0.75);
$bg-module: rgba(35, 45, 65, 0.65);

// Accents - modify these for different LCARS themes
$accent-blue: #4a9eff;
$accent-cyan: #5ad8e6;
$accent-ice: #7dcfff;
$accent-purple: #9580ff;

// Status - warning and critical thresholds
$status-warning: #ff9f43;
$status-critical: #ff5555;
$status-success: #50fa7b;
```

### Threshold Adjustments

The warning (70%) and critical (90%) thresholds are defined in `eww.yuck`. Search for patterns like:

```lisp
{cpu_total >= 90 ? "critical" :
 cpu_total >= 70 ? "warning" : "normal"}
```

### Update Intervals

Modify polling intervals in `eww.yuck`:

```lisp
(defpoll cpu_total :interval "1s" ...)    ; CPU updates every second
(defpoll cpu_temp :interval "2s" ...)     ; Temps update every 2 seconds
(defpoll disk_root_percent :interval "10s" ...)  ; Disk usage every 10 seconds
```

### Panel Sizes

Adjust panel dimensions in `eww.scss`:

```scss
.left-area,
.right-area {
  min-width: 500px;
  max-width: 550px;
}

.left-panel,
.right-panel {
  min-height: 700px;
  max-height: 900px;
}
```

### Different Monitor Resolution

For different resolutions, modify the window geometry in `eww.yuck`:

```lisp
(defwindow lcars-console
  :monitor 0
  :geometry (geometry
              :x "0%"
              :y "0%"
              :width "100%"
              :height "100%"
              :anchor "center center")
  ...)
```

And adjust the main container in `eww.scss`:

```scss
.main-container {
  min-width: 5120px;  // Your monitor width
  min-height: 1440px; // Your monitor height
}
```

## Action Button Customization

The power buttons can be modified in `eww.yuck`. For example, to add confirmation dialogs:

```lisp
; With confirmation dialog (requires zenity or similar)
(button :class "action-btn power"
        :onclick "zenity --question --text='Shutdown?' && systemctl poweroff"
        :tooltip "Power Off"
  ...)
```

## Troubleshooting

### EWW won't start
```bash
# Check for syntax errors
eww logs

# Kill any existing daemon
eww kill
eww daemon
```

### Scripts not working
```bash
# Check permissions
ls -la ~/.config/eww/scripts/

# Test individual scripts
bash -x ~/.config/eww/scripts/cpu.sh total
```

### No temperature readings
```bash
# Install lm_sensors
sudo pacman -S lm_sensors
sudo sensors-detect

# Check available sensors
sensors
```

### Network interface not detected
```bash
# Check your interface name
ip link show

# Modify scripts/network.sh if using a non-standard interface
```

### Warp core animation stuttering
- Reduce animation complexity in `eww.scss`
- Increase update intervals for heavy operations
- Check if compositor (Hyprland) is using hardware acceleration

## File Structure

```
~/.config/eww/
├── eww.yuck           # Widget definitions and layout
├── eww.scss           # Styling and animations
├── scripts/
│   ├── cpu.sh         # CPU usage monitoring
│   ├── memory.sh      # RAM and swap monitoring
│   ├── temperature.sh # CPU/GPU temperature
│   ├── network.sh     # Network stats
│   ├── disk.sh        # Disk usage and I/O
│   └── system-info.sh # Uptime, hostname, etc.
└── README.md          # This file
```

## Performance Notes

- Update intervals are balanced for visual smoothness vs. resource usage
- Network and disk I/O calculations use caching in `/tmp/` for delta calculations
- The warp core animation is CSS-based for GPU acceleration
- Consider reducing poll frequencies if running on lower-end hardware

## Credits

- Inspired by Star Trek: The Next Generation and Star Trek: First Contact LCARS interfaces
- Built with [EWW](https://github.com/elkowar/eww) by ElKowars
- Font: [JetBrains Mono Nerd Font](https://www.nerdfonts.com/)

## License

MIT License - Feel free to modify and share!

---

*"Make it so."* - Captain Jean-Luc Picard
