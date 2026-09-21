# Agent guidance for this dotfiles repo

This repo is a flat collection of personal shell/tool configuration for
arashzandi's Mac. There is no chezmoi/templating layer — files here are
meant to be symlinked or copied directly into place. Secrets are
deliberately excluded (see below); an agent bootstrapping a new machine
from this repo must obtain them separately.

## Repo layout

- `.zshrc`, `.zprofile` — shell config. Sourced by the user's actual
  `~/.zshrc`/`~/.zprofile` (or symlinked in place of them). Defines
  profile-switching (`set_profile`/`profile`), DB CLI wrappers
  (`claude-psql`, `claude-mongosh`, `claude-aws`), a dev-session bootstrap
  (`init`), an AWS security-group `whitelist` helper, and `secrets-drift`.
- `Brewfile` — `brew bundle --file Brewfile` installs everything.
- `.aws/config` — AWS SSO profile definitions (no static credentials).
- `.dbt/.user.yml` — anonymous dbt telemetry ID, harmless.
- `short_cli.py` / `short_fixed.sh` — Shortcut CLI wrapper; reads its API
  token from `SHORTCUT_API_TOKEN` env or `~/.shortcutrc` at runtime, never
  from a file in this repo.
- `.env.secrets.example` — canonical list of every secret env var
  `.zshrc` expects, with empty placeholder values. Safe to read/commit.
- `.env.secrets` — **not in this repo** (gitignored). Real values live
  here, sourced by `.zshrc` at shell startup.

## What's intentionally excluded (see `.gitignore`)

`.env.secrets`, `.aws/sso/`, `.aws/cli/cache/`, `.aws/vpn/`,
`.dbt/dbt_cloud.yml`, `.dbt/profiles.yml`, `.dbt/cloud-cli/`, `mcp.json`,
`.claude.json*`. These either regenerate on login (AWS SSO/CLI caches,
VPN config) or contain live credentials that must be re-entered per
machine, not synced via git.

## Setting up a new machine from this repo

1. Clone this repo to `~/Documents/DOTFILES` (paths in `.zshrc` are
   hardcoded to that location).
2. `brew bundle --file Brewfile`
3. `cp .env.secrets.example .env.secrets` and fill in real values (pull
   them from Keeper, or wherever the previous machine's secrets were
   exported to — see `secrets-drift` below for verifying completeness).
4. Symlink or source `.zshrc`/`.zprofile` from the real `~/.zshrc` /
   `~/.zprofile` — this repo's `.zshrc` already sources
   `~/Documents/DOTFILES/.env.secrets` directly, so no extra wiring is
   needed once the file exists.
5. Re-authenticate AWS SSO (`aws sso login --profile <profile>`) and
   reconnect the VPN client — both regenerate their own local state.
6. Re-create `.dbt/dbt_cloud.yml`, `.dbt/profiles.yml`, and `mcp.json`
   manually; they're gitignored because they embed live tokens/passwords.

## Adding a new secret

Add the `export VAR=` line to both `.env.secrets` (real value) and
`.env.secrets.example` (empty value, same var name) in the same commit
that starts using it. Run `secrets-drift` (defined in `.zshrc`) to
confirm the two files' variable names still match before committing —
it diffs them and reports anything present in one but not the other.

## Verifying no secrets leak before committing

Before any commit that touches `.zshrc`, `.env.secrets.example`, or adds
a new tracked file, run:

```
git diff --cached | grep -inE 'password|secret|token|AKIA[0-9A-Z]{16}|-----BEGIN|mongodb\+srv://[^"]*:[^"]*@|postgres://[^"]*:[^"]*@'
```

Every match should be a comment, a variable name/reference, or a
runtime env-var lookup (`os.environ.get(...)`, `${VAR}`) — never a
literal credential value. If a real secret shows up, stop, remove it,
move it to `.env.secrets`, and re-check before committing.
