
## 🔧 Installation

### One-Line Install (Arch Linux)

**Precompiled binary (default, fast):**
```bash
curl -fsSL https://raw.githubusercontent.com/fibsussy/nmcli-lan-ip-setter/main/install.sh | bash
```

**Or build from source:**
```bash
curl -fsSL https://raw.githubusercontent.com/fibsussy/nmcli-lan-ip-setter/main/install.sh | bash -s local
```

**Note:** For security, inspect the install script before running it. View it [here](https://github.com/fibsussy/nmcli-lan-ip-setter/blob/main/install.sh).

### Manual Installation

#### Prerequisites

Add yourself to the `input` group:
```bash
sudo usermod -a -G input $USER
# Log out and log back in for changes to take effect
```

#### From Source

```bash
# Clone and build
git clone https://github.com/fibsussy/nmcli-lan-ip-setter.git
cd nmcli-lan-ip-setter
cargo build --release

# Install
sudo cp target/release/nmcli-lan-ip-setter /usr/bin/
```

### Post-Installation Setup

1. **Copy the example config:**
```bash
mkdir -p ~/.config/nmcli-lan-ip-setter
cp /usr/share/doc/nmcli-lan-ip-setter/config.example.ron ~/.config/nmcli-lan-ip-setter/config.ron
```

2. **Edit your config:**
```bash
$EDITOR ~/.config/nmcli-lan-ip-setter/config.ron
```

3. **Select which keyboards to enable:**
```bash
nmcli-lan-ip-setter toggle
```


### Manual Install
```sh
git clone https://github.com/fibsussy/nmcli-lan-ip-setter
cd nmcli-lan-ip-setter
makepkg -si
