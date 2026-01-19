<p align="center">
  <img src="https://img.shields.io/badge/shell-bash-blue">
  <img src="https://img.shields.io/github/license/AssortedFood/unix_system_utilities">
  <img src="https://img.shields.io/github/last-commit/AssortedFood/unix_system_utilities">
  <img src="https://img.shields.io/badge/works-on%20my%20machine-success">
</p>

# Unix System Utilities

Personal collection of shell utilities.

## Install

**Fresh Debian 12 minimal (as root):**
```bash
apt update && apt install -y wget && wget -qO- https://github.com/AssortedFood/unix_system_utilities/archive/main.tar.gz | tar xz && cd unix_system_utilities-main && ./install.sh
```

**Fresh Debian 12 minimal (as normal user):**
```bash
sudo apt update && sudo apt install -y wget && wget -qO- https://github.com/AssortedFood/unix_system_utilities/archive/main.tar.gz | tar xz && cd unix_system_utilities-main && ./install.sh
```

**If you have git:**
```bash
git clone https://github.com/AssortedFood/unix_system_utilities.git
cd unix_system_utilities
./install.sh
```

## Installer Options

| Command | Behavior |
|---------|----------|
| `./install.sh` | Install all compatible utilities + deps |
| `./install.sh --select` | Interactive numbered selection |
| `./install.sh --list` | Show available utilities table |
| `./install.sh --uninstall` | Remove from ~/.bashrc |
| `./install.sh --help` | Show help |

## Utilities

| Alias | Description | Platform |
|-------|-------------|----------|
| `copy` | Copy to clipboard (OSC52/xclip/pbcopy) | all |
| `sshl` | SSH with port forwarding profiles | all |
| `sp` | Summarize project files to markdown | all |
| `awt` | Create git worktree with setup | all |
| `rwt` | Remove git worktree safely | all |
| `prompt` | Custom bash prompt with git integration (sourced) | all |
| `tmux-setup` | Install tmux and copy config | all |
| `wsl-bridge` | WSL2 port forwarding to Windows | WSL only |
| `dm` | Termux "did you mean" command correction | Termux only |
