<p align="center">
  <img src="https://img.shields.io/badge/shell-bash-blue">
  <img src="https://img.shields.io/badge/status-internal-orange">
  <img src="https://img.shields.io/badge/repo-private-red">
</p>

<h1 align="center">Unix System Utilities</h1>

A personal collection of small, pragmatic command-line tools designed to make everyday development smoother, faster, and smarter — especially when working with AI.

Each utility is built around real-world needs: concise scripts, often exposed through aliases, that solve recurring problems in seconds. Whether it’s piping questions to an OpenAI model in your terminal, or stitching together all files of a given type for review, these tools are built to stay out of your way and just work.

The goal is simple:  
**Bring clarity, speed, and intelligence to the shell.**

Install the utilities with the following commands:

```bash
git clone https://github.com/AssortedFood/unix_system_utilities.git
cd unix_system_utilities/
bash install.sh
source ~/.bashrc
```

## Notes

### copy_via_osc52

For clipboard copy to work inside tmux (3.3a+), add to your `~/.tmux.conf`:

```
set -g allow-passthrough on
```