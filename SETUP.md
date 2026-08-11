# Personal agent setup

This repository keeps personal agent preferences reproducible without committing credentials or runtime state. The original profile `README.md` is intentionally unchanged.

## Install

```sh
git clone https://github.com/kopenkinda/kopenkinda.git kopenkinda-agents
cd kopenkinda-agents
./bootstrap.sh
```

The bootstrap:

- links the repository's `AGENTS.md` to `~/.codex/AGENTS.md`;
- links files placed in `codex/` into `~/.codex/`;
- links skills placed in `personal-skills/<name>/` into `~/.agents/skills/`;
- installs the curated third-party skills in `third-party-skills.txt` globally for supported agents.

Existing files are moved into a timestamped `~/.codex/backups/kopenkinda-agents/` directory before links are created. Running the bootstrap again is safe.

Use check mode to verify a machine without changing it:

```sh
./bootstrap.sh --check
```

Skip network-backed third-party skill installation when needed:

```sh
./bootstrap.sh --skip-third-party
```

## Customize

- Edit `AGENTS.md` for preferences that should apply in every repository.
- Put authored skills in `personal-skills/<skill-name>/SKILL.md`.
- Edit `third-party-skills.txt` to change installed external skills.
- Put safe, portable Codex configuration files in `codex/`. Do not add `auth.json`, history, databases, caches, tokens, or machine-local state.

Bundled, plugin-provided, and app-managed skills stay managed by their installers and are not copied into this repository.

After changing tracked configuration, rerun `./bootstrap.sh`. Symlinked files and personal skills update immediately; the bootstrap reconciles third-party skills.
