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

# The dotfiles repo owns ~/.codex/AGENTS.md; the bootstrap must leave it alone.
mkdir -p "${TEST_HOME}/.codex"
printf 'global preferences\n' >"${TEST_HOME}/AGENTS.global.md"
ln -s "${TEST_HOME}/AGENTS.global.md" "${TEST_HOME}/.codex/AGENTS.md"

HOME="${TEST_HOME}" AGENT_SETUP_BACKUP_DIR="${TEST_BACKUPS}" \
  "${REPO_DIR}/bootstrap.sh" --skip-third-party

[[ "$(readlink "${TEST_HOME}/.codex/AGENTS.md")" == "${TEST_HOME}/AGENTS.global.md" ]] || exit 1
[[ ! -e "${TEST_BACKUPS}" ]] || exit 1

HOME="${TEST_HOME}" AGENT_SETUP_BACKUP_DIR="${TEST_BACKUPS}" \
  "${REPO_DIR}/bootstrap.sh" --check --skip-third-party

printf 'bootstrap tests passed\n'
