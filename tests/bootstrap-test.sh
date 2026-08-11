#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_DIR
TEST_DIR="$(mktemp -d)"
readonly TEST_DIR
readonly TEST_HOME="${TEST_DIR}/home"
readonly TEST_BACKUPS="${TEST_DIR}/backups"

cleanup() {
  rm -rf "${TEST_DIR}"
}
trap cleanup EXIT

mkdir -p "${TEST_HOME}/.codex"
printf 'old preferences\n' >"${TEST_HOME}/.codex/AGENTS.md"

HOME="${TEST_HOME}" AGENT_SETUP_BACKUP_DIR="${TEST_BACKUPS}" \
  "${REPO_DIR}/bootstrap.sh" --skip-third-party

[[ "${TEST_HOME}/.codex/AGENTS.md" -ef "${REPO_DIR}/AGENTS.md" ]]
[[ "$(find "${TEST_BACKUPS}" -type f -name AGENTS.md | wc -l | tr -d ' ')" == "1" ]]
grep -qx 'old preferences' "$(find "${TEST_BACKUPS}" -type f -name AGENTS.md)"

HOME="${TEST_HOME}" AGENT_SETUP_BACKUP_DIR="${TEST_BACKUPS}" \
  "${REPO_DIR}/bootstrap.sh" --skip-third-party
[[ "$(find "${TEST_BACKUPS}" -type f -name AGENTS.md | wc -l | tr -d ' ')" == "1" ]]

HOME="${TEST_HOME}" AGENT_SETUP_BACKUP_DIR="${TEST_BACKUPS}" \
  "${REPO_DIR}/bootstrap.sh" --check --skip-third-party

printf 'bootstrap tests passed\n'
