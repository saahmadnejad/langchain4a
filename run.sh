#!/usr/bin/env bash
# Source .env (if present) and run a Langchain4a program.
# Usage: ./run.sh [program args...]
#   e.g. ./run.sh my_app

set -eu

ENV_FILE=".env"

if [[ -f "$ENV_FILE" ]]; then
   set -a
   # shellcheck disable=SC1090
   source "$ENV_FILE"
   set +a
fi

if [[ $# -eq 0 ]]; then
   echo "Usage: $0 <executable> [args...]"
   exit 1
fi

exec "$@"
