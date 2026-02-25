<div align="center">

# EXO-PAJI

**Run frontier AI locally with Terminal Green aesthetic**

<p align="center">
  <a href="https://github.com/zirz1911/Exo-Paji" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/GitHub-Exo--Paji-00DC82?logo=github" alt="GitHub"></a>
  <a href="https://github.com/exo-explore/exo" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/Original-exo--explore/exo-blue?logo=github" alt="Original Repo"></a>
  <a href="https://www.apache.org/licenses/LICENSE-2.0.html" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/License-Apache2.0-green.svg" alt="License: Apache-2.0"></a>
</p>

---

**EXO-PAJI** is a customized fork of [exo-explore/exo](https://github.com/exo-explore/exo) with a rebranded Matrix Terminal Green theme and personalized branding.

</div>

## What is EXO-PAJI?

EXO-PAJI connects all your devices into an AI cluster. It enables running models larger than would fit on a single device, and with [day-0 support for RDMA over Thunderbolt](https://x.com/exolabs/status/2001817749744476256?s=20), makes models run faster as you add more devices.

### Key Differences from Original exo

- **Terminal Green Theme**: Rebranded with OKLCH green color scheme (`oklch(0.85 0.20 142)`) inspired by Matrix terminals
- **Custom Branding**: "EXO-PAJI" branding throughout the dashboard
- **Silkscreen Font**: Using Silkscreen for better readability
- **Text-based Logo**: Replaced image logos with glowing text effects

## Features

All features from the original exo, including:

- **Automatic Device Discovery**: Devices running exo automatically discover each other - no manual configuration
- **RDMA over Thunderbolt**: Day-0 support for RDMA over Thunderbolt 5, enabling 99% reduction in latency between devices
- **Topology-Aware Auto Parallel**: Automatically figures out the best way to split models across available devices
- **Tensor Parallelism**: Supports sharding models for up to 1.8x speedup on 2 devices and 3.2x speedup on 4 devices
- **MLX Support**: Uses [MLX](https://github.com/ml-explore/mlx) as inference backend with MLX distributed for distributed communication

## Dashboard

EXO-PAJI includes a customized Terminal Green themed dashboard for managing your cluster and chatting with models.

<p align="center">
  <img src="docs/imgs/dashboard-cluster-view.png" alt="EXO-PAJI dashboard with Terminal Green theme" width="80%" />
</p>

---

## Quick Start

### Prerequisites (macOS)

- [Xcode](https://developer.apple.com/xcode/) (provides Metal ToolChain for MLX compilation)
- [Homebrew](https://brew.sh/) for package management
- [uv](https://github.com/astral-sh/uv) for Python dependency management
- [macmon](https://github.com/vladkens/macmon) for hardware monitoring
- [node](https://nodejs.org/) (version 18+) for building the dashboard
- [rust](https://rustup.rs/) (nightly) for Rust bindings

Install dependencies:

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required packages
brew install uv macmon node

# Install Rust nightly
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup toolchain install nightly
```

### Installation

```bash
# Clone EXO-PAJI
git clone https://github.com/zirz1911/Exo-Paji.git
cd Exo-Paji

# Build the Terminal Green themed dashboard
cd dashboard && npm install && npm run build && cd ..

# Run EXO-PAJI
uv run exo
```

This starts the EXO-PAJI dashboard and API at **http://localhost:52415/**

### Prerequisites (Linux)

```bash
# Install Node.js and npm (Ubuntu/Debian)
sudo apt update
sudo apt install nodejs npm

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Rust nightly
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup toolchain install nightly
```

**Note:** `macmon` is macOS-only and not required for Linux. Currently, exo runs on CPU on Linux; GPU support is under development.

---

## Configuration Options

- `--no-worker`: Run without the worker component (coordinator-only mode for networking/orchestration)

  ```bash
  uv run exo --no-worker
  ```

## File Locations

**macOS:**
- Configuration: `~/Library/Application Support/exo/`
- Cache: `~/Library/Caches/exo/`

**Linux (XDG Base Directory Specification):**
- Configuration: `~/.config/exo/` (or `$XDG_CONFIG_HOME/exo/`)
- Data: `~/.local/share/exo/` (or `$XDG_DATA_HOME/exo/`)
- Cache: `~/.cache/exo/` (or `$XDG_CACHE_HOME/exo/`)

---

## Enabling RDMA on macOS

RDMA requires macOS 26.2+ and works on Macs with Thunderbolt 5 (M4 Pro Mac Mini, M4 Max Mac Studio, M4 Max MacBook Pro, M3 Ultra Mac Studio).

**Steps:**

1. Shut down your Mac
2. Hold power button for 10 seconds until boot menu appears
3. Select "Options" to enter Recovery mode
4. Open Terminal from Utilities menu
5. Type `rdma_ctl enable` and press Enter
6. Reboot your Mac

**Important Caveats:**
- All cluster devices must be interconnected
- Cables must support TB5
- On Mac Studio, cannot use TB5 port next to Ethernet port
- Run `tmp/set_rdma_network_config.sh` when running from source
- Ensure OS versions match exactly across all devices

---

## Using the API

Example using the API to run a model:

```bash
# 1. Preview instance placements
curl "http://localhost:52415/instance/previews?model_id=llama-3.2-1b"

# 2. Create a model instance
curl -X POST http://localhost:52415/instance \
  -H 'Content-Type: application/json' \
  -d '{"instance": {...}}'

# 3. Send a chat completion
curl -N -X POST http://localhost:52415/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "mlx-community/Llama-3.2-1B-Instruct-4bit",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": true
  }'

# 4. Delete the instance
curl -X DELETE http://localhost:52415/instance/YOUR_INSTANCE_ID
```

**Other useful endpoints:**
- List all models: `curl http://localhost:52415/models`
- Inspect state: `curl http://localhost:52415/state`

For more details, see [docs/api.md](docs/api.md) and [src/exo/master/api.py](src/exo/master/api.py).

---

## Benchmarking

Use `exo-bench` to measure model performance:

```bash
uv run bench/exo_bench.py \
  --model Llama-3.2-1B-Instruct-4bit \
  --pp 128,256,512 \
  --tg 128,256 \
  --repeat 3
```

**Key parameters:**
- `--model`: Model to benchmark
- `--pp`: Prompt size hints (comma-separated)
- `--tg`: Generation lengths (comma-separated)
- `--max-nodes`: Limit placements to N nodes
- `--sharding`: Filter by `pipeline`, `tensor`, or `both`
- `--json-out`: Output file for results

---

## Hardware Support

- **macOS**: GPU accelerated (MLX)
- **Linux**: CPU only (GPU support in development)

---

## Credits

**EXO-PAJI** is a customized fork of [exo-explore/exo](https://github.com/exo-explore/exo) maintained by [exo labs](https://x.com/exolabs).

### Theme Customization

- **Color Scheme**: Terminal Green (`oklch(0.85 0.20 142)`)
- **Font**: [Silkscreen](https://fonts.google.com/specimen/Silkscreen) by Jason Kottke
- **Aesthetic**: Matrix/Terminal retro computing

### Original Project

This fork maintains full compatibility with the original exo project. For the latest features and upstream updates, visit:
- **Original Repository**: https://github.com/exo-explore/exo
- **Discord Community**: https://discord.gg/TJ4P57arEm
- **Twitter/X**: https://x.com/exolabs

---

## Contributing

For contributing to EXO-PAJI customizations, please open issues or pull requests in this repository.

For contributing to the core exo functionality, please refer to the original project's [CONTRIBUTING.md](https://github.com/exo-explore/exo/blob/main/CONTRIBUTING.md).

---

## License

Apache License 2.0 - Same as the original exo project

---

<div align="center">
<sub>Built with 💚 by Paji | Powered by <a href="https://github.com/exo-explore/exo">exo</a></sub>
</div>
