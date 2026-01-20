# CLAUDE.md - Dotfiles Context

## Desktop Environment
- **Compositor**: Hyprland (Wayland)
- **Monitor**: 32:9 ultrawide
- **Current launcher**: wofi (considering migration to Walker or Viciane for better extensibility)

## Laptop Environment
- **Compositor**: Hyprland (Wayland)
- **Monitor**: 16:9 full-hd
- **Current launcher**: wofi (considering migration to Walker or Viciane for better extensibility)

## Theme: LCARS Enterprise-E Inspired
A glassy, modern theme inspired by Star Trek Enterprise-E LCARS displays. Design principles:
- Dark base with semi-transparent/glassy elements
- Blue-cyan-ice accent colors for normal states
- White/light grey for text
- **Red reserved strictly for warnings** (high CPU, low battery, critical states)
- No orange/yellow in normal UI - only for warning thresholds

### Color Palette
```css
/* Backgrounds */
bg_dark:       rgba(15, 17, 23, 0.85)
bg_glass:      rgba(25, 30, 45, 0.75)
bg_module:     rgba(35, 45, 65, 0.65)
bg_hover:      rgba(55, 75, 105, 0.80)

/* Borders */
border_dim:    rgba(80, 100, 140, 0.30)
border_bright: rgba(120, 160, 220, 0.50)
border_glow:   rgba(100, 180, 255, 0.60)

/* Text */
text_primary:   #e8edf5
text_secondary: #a8b5c8
text_dim:       #6a7a8f

/* Accents */
accent_blue:   #4a9eff
accent_cyan:   #5ad8e6
accent_ice:    #7dcfff
accent_purple: #9580ff

/* Status */
status_warning:  #ff9f43
status_critical: #ff5555
status_success:  #50fa7b
```

## Completed Components

### Waybar (`~/.config/waybar/`)
- `config.jsonc` - Full config for 32:9 ultrawide with modules: workspaces, window title, media, clock (with seconds), weather (Bern), tray, network, bluetooth, audio, CPU, memory, temperature, battery, power
- `style.css` - LCARS theme with GTK-compatible animations for warning/critical states
- Warning states trigger at 70%, critical at 90% for CPU/memory
- Animations use `animation-name`, `animation-duration` etc. (not shorthand) for GTK compatibility
- Only animate `color` and `background-color` - GTK doesn't support `box-shadow` in keyframes

### Wofi (`~/.config/wofi/`)
- `config` - drun mode, fuzzy matching, centered, 600x400
- `style.css` - Matching LCARS theme
- Note: Removed `transition` and `box-shadow` from entries to fix selection bounce/resize glitch

## TODO / Future Work

### Walker Migration
Walker is the recommended Raycast-like launcher for Linux. Features:
- Built-in modules: apps, calculator, clipboard, files, websearch, emoji, SSH, window switching, AI (Claude/Gemini)
- Simple plugin system via stdin/stdout - can write extensions in any language
- GTK4 + CSS theming
- Runs as service for fast startup

Task: Create Walker theme matching LCARS aesthetic (`~/.config/walker/`)

### Other Components to Theme
- wlogout (power menu)
- dunst/mako (notifications)
- swaylock/hyprlock (lock screen)
- Any other Hyprland components

## Technical Notes

### GTK CSS Limitations (Waybar/Wofi)
- No `box-shadow` in `@keyframes`
- Use expanded animation properties, not shorthand
- Transitions can cause layout reflow/bounce - use sparingly
- `@keyframes` must only animate color/background-color reliably

### Wofi Extensibility
- Limited - requires C plugins compiled to `.so` in `~/.config/wofi/plugins`
- Basic scripting via dmenu mode with stdin/stdout
- For serious extensibility, migrate to Walker or Anyrun

### Font Requirements
Requires a Nerd Font. Preference order:
1. JetBrainsMono Nerd Font
2. CaskaydiaCove Nerd Font
3. FiraCode Nerd Font