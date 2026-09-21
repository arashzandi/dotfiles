# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias python="python3.10"

# AWS IP Whitelist Function
whitelist () {
    who=${1}
    ip=$(curl -s https://checkip.amazonaws.com)
    profile="unset"
    case $who in
    --help)
      echo "Usage: pgbouncer <who or ip> <where>"
      echo "whitelist me # whitelistes my ip on shared account"
      echo "whitelist segment # whitelistes my ip on root account's segment sg"
      echo "whitelist IP # whitelistes IP on shared account"
      echo "whitelist pgbouncer <testing/demo/production> [IP] # whitelists my ip (or IP if given) on bouncer in env"
      ;;
    me)
      echo "hey"
      profile="shared"
      security_group="sg-003510f793c2723ed"
      port=22
      ;;
    segment)
      profile="root"
      security_group="sg-0d9c42c047bfea7e6"
      port=5432
      ;;
    pgbouncer)
      where=${2}
      case $where in
      testing)
        profile=$where
        security_group="sg-070d2438a907b099c"
        port=5432
        ;;
      demo)
        profile=$where
        security_group="sg-074eabbcef9399cc0"
        port=5432
        ;;
      production)
        profile=$where
        security_group="sg-04e24a92a30ef820b"
        port=5432
        ;;
      esac
      # optional 3rd arg: whitelist a specific IP instead of my own
      if [[ -n ${3} ]]; then
        if [[ ${3} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
          ip=${3}
        else
          echo "whitelist: '${3}' is not a valid IPv4 address" >&2
          return 1
        fi
      fi
      ;;
    *)
      ip=$who
      if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        profile="shared"
        security_group="sg-003510f793c2723ed"
        port=22
      fi
      ;;
  esac
  if [[ $profile != "unset" ]]; then
    aws sso login --profile "${profile}"
    AWS_PROFILE="${profile}" aws ec2 authorize-security-group-ingress \
                  --group-id "${security_group}" \
                  --cidr "${ip}/32" \
                  --protocol tcp \
                  --port "${port}"
  else
    echo "whitelist --help"
  fi
}

# Load environment secrets
if [[ -f ~/Documents/DOTFILES/.env.secrets ]]; then
  source ~/Documents/DOTFILES/.env.secrets
fi

# Diff .env.secrets vs .env.secrets.example so a var added to one
# never silently goes missing from the other.
secrets-drift() {
  local dir="$HOME/Documents/DOTFILES"
  local actual="$dir/.env.secrets"
  local example="$dir/.env.secrets.example"

  if [[ ! -f "$actual" ]]; then
    echo "secrets-drift: $actual not found" >&2
    return 1
  fi

  local actual_vars example_vars missing_from_example missing_from_actual
  actual_vars=$(grep -oE '^\s*#?\s*export [A-Z_]+=' "$actual" | grep -oE '[A-Z_]+' | sort -u)
  example_vars=$(grep -oE '^\s*#?\s*export [A-Z_]+=' "$example" | grep -oE '[A-Z_]+' | sort -u)

  missing_from_example=$(comm -23 <(echo "$actual_vars") <(echo "$example_vars"))
  missing_from_actual=$(comm -13 <(echo "$actual_vars") <(echo "$example_vars"))

  if [[ -z "$missing_from_example" && -z "$missing_from_actual" ]]; then
    echo "secrets-drift: .env.secrets and .env.secrets.example are in sync"
    return 0
  fi

  if [[ -n "$missing_from_example" ]]; then
    echo "In .env.secrets but missing from .env.secrets.example:"
    echo "$missing_from_example" | sed 's/^/  /'
  fi
  if [[ -n "$missing_from_actual" ]]; then
    echo "In .env.secrets.example but missing from .env.secrets:"
    echo "$missing_from_actual" | sed 's/^/  /'
  fi
  return 1
}

# Profile Management Function
set_profile() {
  local profile=$1
  
  if [[ -z "$profile" ]]; then
    echo "Current profile: ${PROFILE:-none}"
    echo ""
    echo "Usage: set_profile <testing|production|demo|development|shared>"
    echo ""
    echo "Available profiles:"
    echo "  testing      - Testing environment"
    echo "  production   - Production environment"
    echo "  demo         - Demo environment"
    echo "  development  - Development environment"
    echo "  shared       - Shared AWS profile (AWS only, no DB access)"
    return 1
  fi
  
  # Normalize profile name
  local normalized_profile=""
  case $profile in
    testing|test)
      normalized_profile="testing"
      ;;
    production|prod)
      normalized_profile="production"
      ;;
    demo)
      normalized_profile="demo"
      ;;
    development|dev)
      normalized_profile="development"
      ;;
    shared)
      normalized_profile="shared"
      ;;
    *)
      echo "Error: Unknown profile '$profile'"
      echo "Available profiles: testing, production, demo, development, shared"
      return 1
      ;;
  esac
  
  case $profile in
    testing|test)
      export PROFILE="testing"
      export AWS_PROFILE="testing"
      export POSTGRES_URI="$TESTING_DB_URI"
      export EXPORT_DB_URI="$TESTING_EXPORT_DB_URI"
      export MONGO_URI="$TESTING_MONGO_URI"
      echo "✓ Profile set to: testing"
      ;;
    production|prod)
      export PROFILE="production"
      export AWS_PROFILE="production"
      export POSTGRES_URI="$PRODUCTION_DB_URI"
      export EXPORT_DB_URI="$PRODUCTION_EXPORT_DB_URI"
      export MONGO_URI="$PRODUCTION_MONGO_URI"
      echo "✓ Profile set to: production"
      ;;
    demo)
      export PROFILE="demo"
      export AWS_PROFILE="demo"
      export POSTGRES_URI="$DEMO_DB_URI"
      export EXPORT_DB_URI="$DEMO_EXPORT_DB_URI"
      export MONGO_URI="$DEMO_MONGO_URI"
      echo "✓ Profile set to: demo"
      ;;
    development|dev)
      export PROFILE="development"
      export AWS_PROFILE="development"
      export POSTGRES_URI="$DEVELOPMENT_DB_URI"
      export EXPORT_DB_URI="$DEVELOPMENT_EXPORT_DB_URI"
      export MONGO_URI="$DEVELOPMENT_MONGO_URI"
      echo "✓ Profile set to: development"
      ;;
    shared)
      export PROFILE="shared"
      export AWS_PROFILE="shared"
      # Unset database URIs for shared profile
      unset POSTGRES_URI
      unset EXPORT_DB_URI
      unset MONGO_URI
      echo "✓ Profile set to: shared (AWS only, no database access)"
      ;;
  esac
  
  # Manage Dagster .env file (skip for shared profile)
  if [[ "$normalized_profile" != "shared" ]]; then
    # Try to find marketplace directory: check current dir, then default location
    local dagster_dir=""
    if [[ -d "$PWD/dagster" && -f "$PWD/dagster/example.env" ]]; then
      dagster_dir="$PWD/dagster"
    elif [[ -d "${MARKETPLACE_DIR:-$HOME/Projects/marketplace}/dagster" ]]; then
      dagster_dir="${MARKETPLACE_DIR:-$HOME/Projects/marketplace}/dagster"
    fi

    if [[ -n "$dagster_dir" ]]; then
      local env_source="$dagster_dir/.env.$normalized_profile.local"
      local env_target="$dagster_dir/.env"

      if [[ -f "$env_source" ]]; then
        cp "$env_source" "$env_target"
        echo "✓ Dagster .env file loaded from .env.$normalized_profile.local"
      elif [[ -f "$dagster_dir/example.env" ]]; then
        echo "⚠️  Warning: .env.$normalized_profile.local not found, using example.env as fallback"
        cp "$dagster_dir/example.env" "$env_target"
      else
        echo "⚠️  Warning: No Dagster .env file found for profile '$normalized_profile'"
      fi
    fi
  fi
  
  echo "  AWS_PROFILE: $AWS_PROFILE"
  if [[ -n "$POSTGRES_URI" ]]; then
    echo "  POSTGRES_URI: ${POSTGRES_URI:0:30}..."
  fi
  if [[ -n "$EXPORT_DB_URI" ]]; then
    echo "  EXPORT_DB_URI: ${EXPORT_DB_URI:0:30}..."
  fi
  if [[ -n "$MONGO_URI" ]]; then
    echo "  MONGO_URI: ${MONGO_URI:0:30}..."
  fi
}

# Unset Profile Function
unset_profile() {
  if [[ -n "$PROFILE" ]]; then
    echo "Unsetting profile: $PROFILE"
  else
    echo "No profile currently set"
  fi
  
  unset PROFILE
  unset AWS_PROFILE
  unset POSTGRES_URI
  unset EXPORT_DB_URI
  unset MONGO_URI
  
  echo "✓ All profile environment variables have been unset"
}

# Terminal Title Function
set_terminal_title() {
  local title="$*"

  if [[ -z "$title" ]]; then
    echo "Usage: set_terminal_title <title>"
    echo ""
    echo "Examples:"
    echo "  set_terminal_title My Project Work"
    echo "  set_terminal_title Sync Terminal Title with Chat"
    return 1
  fi

  # Set terminal title using ANSI escape sequence
  echo -ne "\033]0;${title}\007"
  echo "✓ Terminal title set to: ${title}"
}

# Alias for shorter command
alias title="set_terminal_title"

# Alias for shorter command
alias profile="set_profile"

# Safer profile-scoped command wrappers that don't export env vars
_get_profile_uri() {
  local profile=$1
  local uri_type=$2
  local normalized_profile=""

  case $profile in
    testing|test) normalized_profile="testing" ;;
    production|prod) normalized_profile="production" ;;
    backup) normalized_profile="backup" ;;
    demo) normalized_profile="demo" ;;
    development|dev) normalized_profile="development" ;;
    *)
      return 1
      ;;
  esac

  case $normalized_profile in
    testing)
      case $uri_type in
        postgres) echo "$TESTING_DB_URI" ;;
        mongo) echo "$TESTING_MONGO_URI" ;;
        aws) echo "testing" ;;
      esac
      ;;
    production)
      case $uri_type in
        postgres) echo "$PRODUCTION_DB_URI" ;;
        mongo) echo "$PRODUCTION_MONGO_URI" ;;
        aws) echo "production" ;;
      esac
      ;;
    backup)
      case $uri_type in
        mongo) echo "$PRODUCTION_BACKUP_MONGO_URI" ;;
        aws) echo "production" ;;
      esac
      ;;
    demo)
      case $uri_type in
        postgres) echo "$DEMO_DB_URI" ;;
        mongo) echo "$DEMO_MONGO_URI" ;;
        aws) echo "demo" ;;
      esac
      ;;
    development)
      case $uri_type in
        postgres) echo "$DEVELOPMENT_DB_URI" ;;
        mongo) echo "$DEVELOPMENT_MONGO_URI" ;;
        aws) echo "development" ;;
      esac
      ;;
  esac
}

# Wrapper for psql that uses profile-scoped env vars
claude-psql() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: claude-psql <profile> [psql arguments]"
    echo ""
    echo "Examples:"
    echo "  claude-psql production -c 'SELECT COUNT(*) FROM target.campaigns_dataset;'"
    echo "  claude-psql testing -f query.sql"
    echo "  claude-psql prod"
    echo ""
    echo "Available profiles: testing, production, demo, development"
    return 1
  fi

  local profile=$1
  shift

  local uri=$(_get_profile_uri "$profile" "postgres")
  if [[ -z "$uri" ]]; then
    echo "Error: Unknown profile '$profile'" >&2
    echo "Available profiles: testing, production, demo, development" >&2
    return 1
  fi

  POSTGRES_URI="$uri" psql "$uri" "$@"
}

# Wrapper for mongosh that uses profile-scoped env vars
claude-mongosh() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: claude-mongosh <profile> [mongosh arguments]"
    echo ""
    echo "Examples:"
    echo "  claude-mongosh production --quiet --eval 'use deedserver; printjson(db.users.findOne({email: \"test@example.com\"}))'"
    echo "  claude-mongosh testing"
    echo ""
    echo "Available profiles: testing, production, demo, development"
    return 1
  fi

  local profile=$1
  shift

  local uri=$(_get_profile_uri "$profile" "mongo")
  if [[ -z "$uri" ]]; then
    echo "Error: Unknown profile '$profile'" >&2
    echo "Available profiles: testing, production, demo, development" >&2
    return 1
  fi

  MONGO_URI="$uri" mongosh "$uri" "$@"
}

# Wrapper for AWS CLI that uses profile-scoped env vars
claude-aws() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: claude-aws <profile> [aws arguments]"
    echo ""
    echo "Examples:"
    echo "  claude-aws production s3 ls"
    echo "  claude-aws testing ec2 describe-instances"
    echo ""
    echo "Available profiles: testing, production, demo, development"
    return 1
  fi

  local profile=$1
  shift

  local aws_profile=$(_get_profile_uri "$profile" "aws")
  if [[ -z "$aws_profile" ]]; then
    echo "Error: Unknown profile '$profile'" >&2
    echo "Available profiles: testing, production, demo, development" >&2
    return 1
  fi

  # Try the AWS command first
  local output
  local exit_code
  output=$(AWS_PROFILE="$aws_profile" aws "$@" 2>&1)
  exit_code=$?

  # If it failed with SSO session error, login and retry
  if [[ $exit_code -ne 0 ]] && echo "$output" | grep -q "SSO session.*expired\|SSO session.*invalid"; then
    echo "SSO session expired. Running: aws sso login --profile $aws_profile" >&2
    aws sso login --profile "$aws_profile"

    # Retry the command after login
    AWS_PROFILE="$aws_profile" aws "$@"
  else
    # Output the original result
    echo "$output"
    return $exit_code
  fi
}

# Dev Session Init Function
# Logs into AWS SSO + Atlas, whitelists current IP in Atlas projects, and opens VPN
init() {
  echo "========================================="
  echo "  Deed Dev Session Init"
  echo "========================================="
  echo ""

  # Atlas project IDs
  local -A atlas_projects
  atlas_projects=(
    [Production]="594952f8d383ad1a115266fe"
    [Testing]="61de9dca7fea6d7d4679eeb6"
    [Demo]="6401b17f88442704f766c902"
    [Development]="6140c197355aae578be567cc"
  )

  local skip_aws=false
  local skip_atlas=false
  local skip_vpn=false

  # Parse flags
  for arg in "$@"; do
    case $arg in
      --no-aws)   skip_aws=true ;;
      --no-atlas) skip_atlas=true ;;
      --no-vpn)   skip_vpn=true ;;
      --help)
        echo "Usage: init [--no-aws] [--no-atlas] [--no-vpn]"
        echo ""
        echo "Performs full dev session setup:"
        echo "  1. AWS SSO login (all profiles share bonterra SSO)"
        echo "  2. Atlas CLI login + whitelist current IP for 12h"
        echo "  3. Open AWS VPN Client"
        echo ""
        echo "Flags:"
        echo "  --no-aws    Skip AWS SSO login"
        echo "  --no-atlas  Skip Atlas login and IP whitelist"
        echo "  --no-vpn    Skip opening AWS VPN Client"
        return 0
        ;;
    esac
  done

  # --- Step 1: AWS SSO Login ---
  if [[ "$skip_aws" == false ]]; then
    echo "→ [1/3] AWS SSO Login"
    echo "  Logging in via shared profile (covers all profiles)..."
    aws sso login --profile shared
    if [[ $? -eq 0 ]]; then
      echo "  ✓ AWS SSO login successful"
    else
      echo "  ✗ AWS SSO login failed"
    fi
    echo ""
  else
    echo "→ [1/3] AWS SSO Login — skipped"
    echo ""
  fi

  # --- Step 2: Atlas Login + IP Whitelist ---
  if [[ "$skip_atlas" == false ]]; then
    echo "→ [2/3] MongoDB Atlas Login + IP Whitelist"

    # Pre-set output format so atlas auth login doesn't prompt for it
    atlas config set output json 2>/dev/null

    # Check if already authenticated
    local atlas_check
    atlas_check=$(atlas project ls --output json 2>&1)
    if echo "$atlas_check" | grep -q "session expired\|Unauthorized\|not logged in\|auth login"; then
      echo "  Atlas session expired, logging in..."
      # Run interactively rather than scripting the auth-type TUI via
      # expect: expect-driven sends to this prompt were unreliable across
      # machines (hung waiting for the selector to advance even with
      # retries), so just let the user drive it directly.
      echo "  (interactive — select UserAccount and follow the prompts)"
      atlas auth login
    else
      echo "  ✓ Atlas session already active"
    fi

    # Get current IP early to decide whether to whitelist.
    # Force IPv4: on networks where ifconfig.me resolves to an IPv6
    # address, `atlas accessList create --currentIp` fails with
    # "unable to find your public IP address" because it can't use the
    # IPv6 result. We pass the IPv4 address explicitly to atlas instead
    # of relying on --currentIp's own (broken) detection.
    local my_ip
    my_ip=$(curl -s -4 https://ifconfig.me)
    local known_ip="217.110.181.244"

    if [[ -z "$my_ip" ]]; then
      echo "  ✗ Failed to detect public IP"
    elif [[ "$my_ip" == "$known_ip" ]]; then
      echo "  IP: $my_ip (already permanently whitelisted — skipping)"
    else
      echo "  IP: $my_ip"

      # Discover backup projects dynamically
      local all_projects
      all_projects=$(atlas project ls --output json 2>/dev/null)
      if [[ -n "$all_projects" ]]; then
        local backup_ids
        backup_ids=$(echo "$all_projects" | python3 -c "
import sys, json
data = json.load(sys.stdin)
results = data.get('results', data) if isinstance(data, dict) else data
for p in results:
    name = p.get('name', '')
    pid = p.get('id', '')
    if 'backup' in name.lower():
        print(f'{pid}|{name}')
" 2>/dev/null)
        while IFS='|' read -r bid bname; do
          if [[ -n "$bid" ]]; then
            atlas_projects["$bname"]="$bid"
          fi
        done <<< "$backup_ids"
      fi

      # Calculate expiry (12 hours from now)
      local expiry
      expiry=$(date -u -v+12H '+%Y-%m-%dT%H:%M:%SZ')
      echo "  Expires: $expiry"
      echo ""

      # Whitelist on all projects
      local project_name project_id
      for project_name in ${(ko)atlas_projects}; do
        project_id="${atlas_projects[$project_name]}"
        printf "  %-25s " "$project_name"
        local result
        result=$(atlas accessList create "$my_ip" --type ipAddress \
          --projectId "$project_id" \
          --comment "arash dev access (12h)" \
          --deleteAfter "$expiry" \
          --output json 2>&1)
        if [[ $? -eq 0 ]]; then
          echo "✓ whitelisted"
        elif echo "$result" | grep -qi "ALREADY_EXISTS\|already exists\|duplicate"; then
          echo "✓ already whitelisted"
        else
          echo "✗ failed: $(echo "$result" | head -1)"
        fi
      done
    fi
    echo ""
  else
    echo "→ [2/3] MongoDB Atlas — skipped"
    echo ""
  fi

  # --- Step 3: AWS VPN Client ---
  if [[ "$skip_vpn" == false ]]; then
    echo "→ [3/3] AWS VPN Client"

    local vpn_cli="/usr/local/bin/aws-vpn-client"
    local vpn_profile="deed"

    if [[ ! -x "$vpn_cli" ]]; then
      # Fallback: just open the app for manual connect if the CLI isn't installed
      echo "  ✗ $vpn_cli not found — opening app for manual connect"
      open "/Applications/AWS VPN Client/AWS VPN Client.app"
    else
      local vpn_status
      vpn_status=$("$vpn_cli" get-connection-status --profile-name "$vpn_profile" 2>/dev/null \
        | python3 -c 'import json,sys; print(json.load(sys.stdin).get("connection-status",""))' 2>/dev/null)

      if [[ "$vpn_status" == "Connected" ]]; then
        echo "  ✓ VPN already connected ($vpn_profile)"
      else
        echo "  Connecting VPN ($vpn_profile)... this may open a browser for SAML SSO"
        # The AWS VPN Client GUI is Electron-based and exposes no accessible
        # button names, so AppleScript UI clicking (the old approach) can never
        # reliably find/click "Connect". The CLI talks to the same daemon directly.
        if "$vpn_cli" connect --profile-name "$vpn_profile"; then
          echo "  ✓ VPN connection initiated ($vpn_profile)"
        else
          echo "  ✗ Could not connect VPN via CLI — falling back to opening the app"
          open "/Applications/AWS VPN Client/AWS VPN Client.app"
        fi
      fi
    fi
    echo ""
  else
    echo "→ [3/3] AWS VPN Client — skipped"
    echo ""
  fi

  echo "========================================="
  echo "  Init complete!"
  echo "========================================="
}

# Resume prior Claude Code context cheaply via a handoff checkpoint,
# instead of --resume (which replays the whole old transcript).
# Usage: cld <slug|ticket|keyword> [extra claude args...]
#   cld sc-95337
#   cld hd-review-fields --model opus
# With no args, starts a fresh opusplan session (skip permissions) with no
# handoff — handy for e.g. `cld` then `/ticket BDP-6331`.
cld() {
  local index_path="$HOME/.claude/handoffs/index.json"

  if [[ $# -lt 1 ]]; then
    echo "Starting fresh Claude session (opusplan, skip permissions), no handoff."
    if [[ -f "$index_path" ]]; then
      echo ""
      echo "Known handoffs:"
      python3 -c "
import json
idx = json.load(open('$index_path'))
for slug, meta in sorted(idx.items(), key=lambda kv: kv[1].get('updatedAt', ''), reverse=True):
    print(f\"  {slug:30s} {meta.get('updatedAt','?'):20s} {meta.get('summary','')}\")
"
      echo ""
      echo "Usage: cld <slug|ticket|keyword> [extra claude args...]"
    fi
    claude --model opusplan --dangerously-skip-permissions
    return $?
  fi

  local query=$1
  shift

  if [[ ! -f "$index_path" ]]; then
    echo "Error: no handoff index found at $index_path" >&2
    echo "Run /handoff or /touch in a Claude session first." >&2
    return 1
  fi

  # Resolve query -> handoff file. Exact slug match first, then substring
  # match against slug/ticket text, then keyword match against summary.
  local handoff_file
  handoff_file=$(python3 -c "
import json, sys, re

query = sys.argv[1].strip().lower()
query_norm = re.sub(r'^(sc-|#)', '', query)
idx = json.load(open(sys.argv[2]))

# 1. exact slug match
if query in idx:
    print(idx[query]['file']); sys.exit(0)

# 2. slug normalized match (sc-95337 vs 95337 vs #95337)
for slug, meta in idx.items():
    if re.sub(r'^(sc-|#)', '', slug.lower()) == query_norm:
        print(meta['file']); sys.exit(0)

# 3. substring match on slug
candidates = [(slug, meta) for slug, meta in idx.items() if query in slug.lower()]
if len(candidates) == 1:
    print(candidates[0][1]['file']); sys.exit(0)

# 4. keyword match on summary
candidates = [(slug, meta) for slug, meta in idx.items() if query in meta.get('summary', '').lower()]
if len(candidates) == 1:
    print(candidates[0][1]['file']); sys.exit(0)

sys.exit(1)
" "$query" "$index_path" 2>/dev/null)

  if [[ -z "$handoff_file" ]]; then
    echo "No unique handoff match for '$query'." >&2
    echo "Run /recall \"$query\" in a Claude session to search more broadly, or 'cld' with no args to list known slugs." >&2
    return 1
  fi

  local handoff_path="$HOME/.claude/handoffs/$handoff_file"
  if [[ ! -f "$handoff_path" ]]; then
    echo "Error: index points to missing file $handoff_path" >&2
    return 1
  fi

  echo "Starting fresh Claude session with handoff: $handoff_path"
  claude --append-system-prompt "$(cat "$handoff_path")" --dangerously-skip-permissions "$@"
}

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Fix SSL certificate issue for Shortcut CLI
export NODE_TLS_REJECT_UNAUTHORIZED=0

# Shortcut CLI wrapper alias
alias short-cli='~/short_fixed.sh'
alias python3=python3.10

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# SENTRY_AUTH_TOKEN loaded from .env.secrets
export SENTRY_ORG=deed

# ANTHROPIC_API_KEY loaded from .env.secrets (kept commented out here; uncomment to use)
# export ANTHROPIC_API_KEY

#PAYPAL API KEYS (PAYPAL_CLIENTID / PAYPAL_SECRET loaded from .env.secrets)
export PAYPAL_ENDPOINT="https://api.paypal.com/v1"

# Sigma Computing API (SIGMA_CLIENT_ID / SIGMA_CLIENT_SECRET loaded from .env.secrets)

export PATH="/Users/arash/.local/bin:$PATH"
# Cortex CLI completion (disable via /settings in cortex)
[[ -s ~/.zsh/completions/cortex.zsh ]] && source ~/.zsh/completions/cortex.zsh
