use anyhow::{Context, Result};
use notify::{Config, Event, EventKind, RecommendedWatcher, RecursiveMode, Watcher};
use reqwest::multipart;
use serde::Deserialize;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::mpsc::channel;
use tokio::runtime::Runtime;

#[derive(Debug, Deserialize)]
struct AppConfig {
    discord_webhook: String,
    watch_dir: String,
}

fn find_config() -> Result<AppConfig> {
    // Priority order: exec dir > .config/filecord > /etc/filecord
    let config_paths = vec![
        PathBuf::from("filecord.conf"),
        dirs::config_dir()
            .map(|p| p.join("filecord/filecord.conf"))
            .unwrap_or_default(),
        PathBuf::from("/etc/filecord/filecord.conf"),
    ];

    for path in config_paths {
        if path.exists() {
            let content = fs::read_to_string(&path)
                .with_context(|| format!("Failed to read config file: {:?}", path))?;
            let config: AppConfig = toml::from_str(&content)
                .with_context(|| format!("Failed to parse config file: {:?}", path))?;
            println!("Loaded config from: {:?}", path);
            return Ok(config);
        }
    }

    anyhow::bail!("No config file found. Please create filecord.conf in current directory, ~/.config/filecord/, or /etc/filecord/")
}

async fn send_file_to_discord(webhook_url: &str, file_path: &Path) -> Result<()> {
    let file_name = file_path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown");

    let file_content = fs::read(file_path)
        .with_context(|| format!("Failed to read file: {:?}", file_path))?;

    let file_size = file_content.len();
    
    // Only send files below 200KB (200 * 1024 bytes)
    if file_size > 200 * 1024 {
        println!("Skipping {}: file size {}KB exceeds 200KB limit", file_name, file_size / 1024);
        return Ok(());
    }

    println!("Sending {} ({}KB) to Discord...", file_name, file_size / 1024);

    let part = multipart::Part::bytes(file_content)
        .file_name(file_name.to_string());

    let form = multipart::Form::new()
        .text("content", format!("New file detected: {}", file_name))
        .part("file", part);

    let client = reqwest::Client::new();
    let response = client
        .post(webhook_url)
        .multipart(form)
        .send()
        .await
        .context("Failed to send file to Discord")?;

    if response.status().is_success() {
        println!("Successfully sent {} to Discord", file_name);
    } else {
        println!("Failed to send file: HTTP {}", response.status());
    }

    Ok(())
}

fn watch_directory(config: AppConfig) -> Result<()> {
    let watch_path = PathBuf::from(&config.watch_dir);
    
    if !watch_path.exists() {
        anyhow::bail!("Watch directory does not exist: {}", config.watch_dir);
    }

    println!("Watching directory: {}", config.watch_dir);
    println!("Monitoring for new files...");

    let (tx, rx) = channel();

    let mut watcher = RecommendedWatcher::new(tx, Config::default())
        .context("Failed to create file watcher")?;

    watcher
        .watch(&watch_path, RecursiveMode::Recursive)
        .with_context(|| format!("Failed to watch directory: {}", config.watch_dir))?;

    let rt = Runtime::new().context("Failed to create Tokio runtime")?;

    for res in rx {
        match res {
            Ok(Event {
                kind: EventKind::Create(_),
                paths,
                ..
            }) => {
                for path in paths {
                    if path.is_file() {
                        println!("New file detected: {:?}", path);
                        
                        let webhook_url = config.discord_webhook.clone();
                        if let Err(e) = rt.block_on(send_file_to_discord(&webhook_url, &path)) {
                            eprintln!("Error sending file to Discord: {}", e);
                        }
                    }
                }
            }
            Ok(_event) => {
                // Ignore other events (modify, delete, etc.)
            }
            Err(e) => {
                eprintln!("Watch error: {:?}", e);
            }
        }
    }

    Ok(())
}

fn main() -> Result<()> {
    println!("Filecord - File Monitor and Discord Uploader");
    println!("===========================================");

    let config = find_config()?;
    watch_directory(config)?;

    Ok(())
}
