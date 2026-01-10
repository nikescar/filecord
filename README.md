# Filecord

A Rust application that monitors directories for new files and automatically uploads them to Discord via webhooks.

## Features

- **Recursive Directory Monitoring**: Watches a specified directory and all its subdirectories for new files
- **Discord Integration**: Automatically uploads new files to Discord using webhooks
- **File Size Filtering**: Only sends files under 200KB to comply with Discord's limits
- **Flexible Configuration**: Supports multiple config file locations with priority order
- **Real-time Detection**: Uses inotify (Linux) for efficient file system monitoring

## Configuration

Create a `filecord.conf` file in one of these locations (checked in order):

1. Current executable directory: `./filecord.conf`
2. User config directory: `~/.config/filecord/filecord.conf`
3. System config directory: `/etc/filecord/filecord.conf`

### Configuration Format (TOML)

```toml
# Discord webhook URL (required)
discord_webhook = "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"

# Directory to watch for new files (required)
watch_dir = "/path/to/watch"
```

### Getting a Discord Webhook URL

1. Open Discord and go to Server Settings
2. Navigate to Integrations > Webhooks
3. Click "New Webhook" or select an existing one
4. Copy the Webhook URL
5. Paste it into your `filecord.conf`

## Installation

### Build from Source

```bash
# Clone or navigate to the project directory
cd /root/work/filecord

# Build the release version
cargo build --release

# The binary will be at target/release/filecord
```

### Install System-wide

```bash
# Build release version
cargo build --release

# Copy binary to system path
sudo cp target/release/filecord /usr/local/bin/

# Create config directory
mkdir -p ~/.config/filecord/

# Copy and edit config
cp filecord.conf.example ~/.config/filecord/filecord.conf
nano ~/.config/filecord/filecord.conf
```

## Usage

```bash
# Run with config in current directory
./target/release/filecord

# Or if installed system-wide
filecord
```

The application will:
1. Load configuration from the first available config file
2. Start monitoring the specified directory recursively
3. Detect any new files created in the directory or subdirectories
4. Upload files under 200KB to Discord with a notification message
5. Continue running until stopped (Ctrl+C)

## Example Output

```
Filecord - File Monitor and Discord Uploader
===========================================
Loaded config from: "filecord.conf"
Watching directory: /home/user/downloads
Monitoring for new files...
New file detected: "/home/user/downloads/document.pdf"
Sending document.pdf (45KB) to Discord...
Successfully sent document.pdf to Discord
```

## File Size Limits

- **Maximum file size**: 200KB (204,800 bytes)
- Files larger than 200KB are detected but not uploaded
- A message is printed when files exceed the size limit

## Requirements

- Linux (uses inotify for file monitoring)
- Rust 1.70 or later
- Internet connection for Discord API access

## Dependencies

- `notify` - File system monitoring
- `reqwest` - HTTP client for Discord API
- `tokio` - Async runtime
- `serde` & `toml` - Configuration parsing
- `anyhow` - Error handling
- `dirs` - Config directory detection

## Troubleshooting

### "No config file found" error
- Ensure `filecord.conf` exists in one of the supported locations
- Check file permissions (must be readable)

### "Watch directory does not exist" error
- Verify the `watch_dir` path in your config file is correct
- Ensure the directory exists and is accessible

### Files not uploading
- Verify the Discord webhook URL is correct
- Check that files are under 200KB
- Ensure you have internet connectivity
- Check Discord webhook is not rate-limited

## License

MIT
