# Puckadots AI Context

This repository is **Puckadots**, a modular dotfiles framework.

## Architecture

- **Public/Private Split**:
  - `dotfiles` (Public): Contains the "Engine" (scripts, tools, defaults).
  - `sshsync` (Private): Contains user data, SSH keys, and custom dotfiles.
  
- **OS Abstraction**:
  - `lib/os.sh` detects distro (`apt`, `dnf`, `pacman`) and abstracts package management.
  - Scripts should NEVER use `apt install` directly. Use `pkg_install`.

- **Configuration**:
  - `config/symlinks.conf`: Maps repository files to `$HOME`.
  - `config/zsh/`: Modular Zsh config (`init.zsh`, `aliases.zsh`, etc.).
  - `config/help.dat`: Data source for `dothelp`.

## Development Rules

1. **Idempotency**: All scripts (sync, setup) must be safe to re-run.
2. **Modularity**: Don't put everything in one file. Use the `config/` subdirectories.
3. **Data-Driven**: Use `help.dat` and `keys.dat` for documentation, not hardcoded strings.
4. **Private by Default**: User additions go to `sshsync`, not here.

## Key Commands

- `updatep`: Updates system packages via `bin/update-system`.
- `dotpull`: Updates repo and runs `sync.sh`.
- `add-dotfile`: Moves file to `sshsync` and links it.
