.PHONY: all build build-x64 build-arm64 clean install install-x64 install-arm64 help

# Project name
PROJECT = filecord

# Build directories
BUILD_DIR_X64 = target/release
BUILD_DIR_ARM64 = target/aarch64-unknown-linux-gnu/release

# Binary paths
BIN_X64 = $(BUILD_DIR_X64)/$(PROJECT)
BIN_ARM64 = $(BUILD_DIR_ARM64)/$(PROJECT)

# Install directory
PREFIX ?= /usr/local
INSTALL_DIR = $(PREFIX)/bin

# Default target
all: build

# Build both architectures
build: build-x64 build-arm64

# Build x86_64 version
build-x64:
	@echo "Building x86_64 binary..."
	cargo build --release
	@echo "✓ x86_64 binary: $(BIN_X64)"

# Build ARM64/aarch64 version
build-arm64:
	@echo "Building ARM64 binary..."
	cargo build --release --target aarch64-unknown-linux-gnu
	@echo "✓ ARM64 binary: $(BIN_ARM64)"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	cargo clean
	@echo "✓ Clean complete"

# Install both binaries (requires root)
install: build
	@echo "Installing binaries to $(INSTALL_DIR)..."
	install -d $(INSTALL_DIR)
	install -m 755 $(BIN_X64) $(INSTALL_DIR)/$(PROJECT)
	install -m 755 $(BIN_ARM64) $(INSTALL_DIR)/$(PROJECT)-arm64
	@echo "✓ Installed:"
	@echo "  - $(INSTALL_DIR)/$(PROJECT) (x86_64)"
	@echo "  - $(INSTALL_DIR)/$(PROJECT)-arm64 (ARM64)"

# Install x86_64 binary only
install-x64: build-x64
	@echo "Installing x86_64 binary to $(INSTALL_DIR)..."
	install -d $(INSTALL_DIR)
	install -m 755 $(BIN_X64) $(INSTALL_DIR)/$(PROJECT)
	@echo "✓ Installed: $(INSTALL_DIR)/$(PROJECT) (x86_64)"

# Install ARM64 binary only
install-arm64: build-arm64
	@echo "Installing ARM64 binary to $(INSTALL_DIR)..."
	install -d $(INSTALL_DIR)
	install -m 755 $(BIN_ARM64) $(INSTALL_DIR)/$(PROJECT)-arm64
	@echo "✓ Installed: $(INSTALL_DIR)/$(PROJECT)-arm64 (ARM64)"

# Setup cross-compilation toolchain
setup:
	@echo "Setting up cross-compilation environment..."
	@echo "Adding ARM64 target..."
	rustup target add aarch64-unknown-linux-gnu
	@echo "Installing ARM64 cross-compiler (requires apt)..."
	@command -v apt-get >/dev/null 2>&1 && \
		sudo apt-get update && \
		sudo apt-get install -y gcc-aarch64-linux-gnu || \
		echo "⚠ apt-get not found, please manually install gcc-aarch64-linux-gnu"
	@echo "✓ Setup complete"

# Check binary architectures
check:
	@echo "Checking binary architectures..."
	@if [ -f "$(BIN_X64)" ]; then \
		echo "x86_64:"; \
		file $(BIN_X64); \
		ls -lh $(BIN_X64); \
	else \
		echo "x86_64 binary not found (run: make build-x64)"; \
	fi
	@echo ""
	@if [ -f "$(BIN_ARM64)" ]; then \
		echo "ARM64:"; \
		file $(BIN_ARM64); \
		ls -lh $(BIN_ARM64); \
	else \
		echo "ARM64 binary not found (run: make build-arm64)"; \
	fi

# Run tests
test:
	@echo "Running tests..."
	cargo test

# Format code
fmt:
	@echo "Formatting code..."
	cargo fmt

# Run clippy linter
lint:
	@echo "Running clippy..."
	cargo clippy -- -D warnings

# Show help
help:
	@echo "Filecord Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build both x86_64 and ARM64 binaries (default)"
	@echo "  build        - Build both x86_64 and ARM64 binaries"
	@echo "  build-x64    - Build x86_64 binary only"
	@echo "  build-arm64  - Build ARM64 binary only"
	@echo "  clean        - Remove build artifacts"
	@echo "  install      - Install both binaries to $(PREFIX)/bin"
	@echo "  install-x64  - Install x86_64 binary only"
	@echo "  install-arm64- Install ARM64 binary only"
	@echo "  setup        - Setup cross-compilation toolchain"
	@echo "  check        - Verify built binaries"
	@echo "  test         - Run tests"
	@echo "  fmt          - Format code"
	@echo "  lint         - Run clippy linter"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Build both architectures"
	@echo "  make build-arm64        # Build ARM64 only"
	@echo "  make install PREFIX=~/.local  # Install to custom directory"
	@echo "  make check              # Verify binaries"
