# Build Instructions

## Cross-Compilation for ARM64 Linux

This project has been successfully configured for cross-compilation to ARM64 Linux targets.

### Available Binaries

After building, you'll have both architectures available:

- **x86_64 Linux**: `target/release/filecord` (6.2 MB)
- **ARM64 Linux**: `target/aarch64-unknown-linux-gnu/release/filecord` (6.1 MB)

### Build Commands

#### Build for x86_64 (Native)
```bash
cargo build --release
```

#### Build for ARM64/aarch64
```bash
cargo build --release --target aarch64-unknown-linux-gnu
```

### Cross-Compilation Setup (Already Configured)

The project includes:

1. **Cargo Configuration** (`.cargo/config.toml`):
   - Linker configured for ARM64 target
   - Uses `aarch64-linux-gnu-gcc`

2. **Dependencies**:
   - Uses `rustls-tls` instead of native OpenSSL for easier cross-compilation
   - All dependencies are compatible with cross-compilation

### System Requirements for Cross-Compilation

To build for ARM64 on an x86_64 system, you need:

```bash
# Add ARM64 target to Rust
rustup target add aarch64-unknown-linux-gnu

# Install ARM64 cross-compiler (Debian/Ubuntu)
apt-get update
apt-get install -y gcc-aarch64-linux-gnu
```

### Verifying Binaries

```bash
# Check architecture
file target/release/filecord
# Output: ELF 64-bit LSB pie executable, x86-64, ...

file target/aarch64-unknown-linux-gnu/release/filecord
# Output: ELF 64-bit LSB pie executable, ARM aarch64, ...
```

### Deployment

Both binaries are standalone executables that can be deployed to their respective platforms:

```bash
# Copy to ARM64 device
scp target/aarch64-unknown-linux-gnu/release/filecord user@arm64-device:/usr/local/bin/

# Copy to x86_64 device  
scp target/release/filecord user@x86_64-device:/usr/local/bin/
```

### Configuration

Both binaries use the same configuration format. Create `filecord.conf`:

```toml
discord_webhook = "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"
watch_dir = "/path/to/watch"
```

Place it in one of these locations:
- Current directory: `./filecord.conf`
- User config: `~/.config/filecord/filecord.conf`
- System config: `/etc/filecord/filecord.conf`

### Testing on ARM64

To test on an ARM64 device:

```bash
# Transfer the binary
scp target/aarch64-unknown-linux-gnu/release/filecord user@raspberry-pi:~/

# On the ARM64 device
chmod +x filecord
./filecord
```

## Build Notes

- Both binaries are dynamically linked
- ARM64 binary requires: `/lib/ld-linux-aarch64.so.1`
- x86_64 binary requires: `/lib64/ld-linux-x86-64.so.2`
- Uses Rust 2021 edition
- Optimized for release builds
