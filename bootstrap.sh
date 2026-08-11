#!/usr/bin/env bash

set -euo pipefail

readonly SKILLS_CLI_VERSION="1.5.22"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR
readonly CODEX_DIR="${CODEX_HOME:-${HOME:?HOME must be set}/.codex}"
readonly USER_AGENTS_DIR="${AGENTS_HOME:-${HOME:?HOME must be set}/.agents}"
readonly MANIFEST_FILE="${REPO_DIR}/third-party-skills.txt"

mode="install"
install_third_party="true"
check_failed="false"
backup_root=""

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [--check] [--skip-third-party]

  --check              Verify links and installed skills without changing files.
  --skip-third-party   Do not install or check skills from third-party-skills.txt.
  -h, --help           Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --check)
      mode="check"
      ;;
    --skip-third-party)
      install_third_party="false"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

validate_manifest() {
  local line_number=0
  local source=""
  local skill=""
  local extra=""

  [[ -f "${MANIFEST_FILE}" ]] || {
    printf 'Missing manifest: %s\n' "${MANIFEST_FILE}" >&2
    exit 1
  }

  while read -r source skill extra; do
    ((line_number += 1))
    [[ -z "${source}" || "${source}" == \#* ]] && continue
    if [[ -z "${skill}" || -n "${extra}" ]]; then
      printf 'Invalid manifest entry at %s:%d\n' "${MANIFEST_FILE}" "${line_number}" >&2
      exit 1
    fi
  done <"${MANIFEST_FILE}"
}

ensure_backup_root() {
  if [[ -z "${backup_root}" ]]; then
    backup_root="${AGENT_SETUP_BACKUP_DIR:-${CODEX_DIR}/backups/kopenkinda-agents/$(date -u +%Y%m%dT%H%M%SZ)}"
  fi
}

backup_destination() {
  local destination="$1"
  local backup_destination=""

  ensure_backup_root
  backup_destination="${backup_root}${destination}"
  mkdir -p "$(dirname "${backup_destination}")"
  mv "${destination}" "${backup_destination}"
  printf 'Backed up %s to %s\n' "${destination}" "${backup_destination}"
}

link_entry() {
  local source="$1"
  local destination="$2"

  if [[ -e "${destination}" && "${destination}" -ef "${source}" ]]; then
    printf 'OK %s\n' "${destination}"
    return
  fi

  if [[ "${mode}" == "check" ]]; then
    printf 'MISSING %s -> %s\n' "${destination}" "${source}" >&2
    check_failed="true"
    return
  fi

  mkdir -p "$(dirname "${destination}")"
  if [[ -e "${destination}" || -L "${destination}" ]]; then
    backup_destination "${destination}"
  fi
  ln -s "${source}" "${destination}"
  printf 'Linked %s -> %s\n' "${destination}" "${source}"
}

install_managed_files() {
  local source=""
  local relative_path=""

  link_entry "${REPO_DIR}/AGENTS.md" "${CODEX_DIR}/AGENTS.md"

  while IFS= read -r -d '' source; do
    relative_path="${source#"${REPO_DIR}/codex/"}"
    link_entry "${source}" "${CODEX_DIR}/${relative_path}"
  done < <(find "${REPO_DIR}/codex" -type f ! -name '.gitkeep' -print0)
}

install_personal_skills() {
  local skill_dir=""

  for skill_dir in "${REPO_DIR}"/personal-skills/*; do
    [[ -d "${skill_dir}" && -f "${skill_dir}/SKILL.md" ]] || continue
    link_entry "${skill_dir}" "${USER_AGENTS_DIR}/skills/$(basename "${skill_dir}")"
  done
}

check_third_party_skills() {
  local source=""
  local skill=""
  local extra=""
  local skill_file=""

  while read -r source skill extra; do
    [[ -z "${source}" || "${source}" == \#* ]] && continue
    skill_file="${USER_AGENTS_DIR}/skills/${skill}/SKILL.md"
    if [[ -f "${skill_file}" ]]; then
      printf 'OK %s\n' "${skill_file}"
    else
      printf 'MISSING %s (from %s)\n' "${skill_file}" "${source}" >&2
      check_failed="true"
    fi
  done <"${MANIFEST_FILE}"
}

install_third_party_skills() {
  local package=""
  local source=""
  local skill=""
  local extra=""
  local -a skill_names=()

  command -v npx >/dev/null 2>&1 || {
    printf 'npx is required to install third-party skills.\n' >&2
    exit 1
  }

  while read -r package; do
    skill_names=()
    while read -r source skill extra; do
      [[ -z "${source}" || "${source}" == \#* ]] && continue
      [[ "${source}" == "${package}" ]] && skill_names+=("${skill}")
    done <"${MANIFEST_FILE}"

    printf 'Installing %d skill(s) from %s\n' "${#skill_names[@]}" "${package}"
    npx --yes "skills@${SKILLS_CLI_VERSION}" add "${package}" \
      --global --agent '*' --skill "${skill_names[@]}" --yes
  done < <(awk '!/^[[:space:]]*(#|$)/ && !seen[$1]++ { print $1 }' "${MANIFEST_FILE}")
}

validate_manifest
install_managed_files
install_personal_skills

if [[ "${install_third_party}" == "true" ]]; then
  if [[ "${mode}" == "check" ]]; then
    check_third_party_skills
  else
    install_third_party_skills
  fi
fi

if [[ "${check_failed}" == "true" ]]; then
  printf 'Agent setup check failed. Run ./bootstrap.sh to reconcile it.\n' >&2
  exit 1
fi

if [[ "${mode}" == "check" ]]; then
  printf 'Agent setup is current.\n'
else
  printf 'Agent setup complete. Restart Codex if new skills do not appear immediately.\n'
fi
