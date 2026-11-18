#!/usr/bin/env bash
# worker-template.sh — copy to bin/<name>, fill in the TODOs, re-run install.sh.
#
# Turns any AI coding CLI that has a headless/"print" mode into a worker that
# Claude Code (the manager) can call from Bash:
#     <name> "question"        read-only
#     <name> -w "task"         may edit files in the current directory
#
# Find your CLI's flags with `<cli> --help`. You need:
#   1. a non-interactive mode that prints the answer and exits (-p, exec, run …)
#   2. a model flag (optional)
#   3. a way to restrict tools: read-only/plan mode vs. auto-accept edits,
#      ideally scoped to the working directory
#   4. ideally JSON output, so you can detect errors and denied tools
set -euo pipefail

[[ -z "${WORKER_DEPTH:-}" ]] || { echo "refusing to nest workers" >&2; exit 2; }
export WORKER_DEPTH=1

write=0; model="${MYWORKER_MODEL:-}"   # TODO: default model id
while getopts "wm:" opt; do
  case "$opt" in w) write=1 ;; m) model="$OPTARG" ;; *) exit 2 ;; esac
done
shift $((OPTIND - 1))
prompt="${*:-}"; [[ -n "$prompt" || -t 0 ]] || prompt="$(cat)"
[[ -n "$prompt" ]] || { echo "no prompt" >&2; exit 2; }

if (( write )); then
  perm=(--TODO-auto-accept-edits-flag)      # e.g. --mode accept-edits / --full-auto
else
  perm=(--TODO-read-only-flag)              # e.g. --mode plan / --sandbox read-only
fi

# TODO: replace `mycli` and flags with the real command.
out="$(mycli --TODO-headless-flag "$prompt" ${model:+--model "$model"} "${perm[@]}" </dev/null)"

echo "$out"
# If the CLI returns JSON: print only the answer field, log the call, and
# `exit 3` when it reports a denied tool, so the manager knows to narrow the task.
