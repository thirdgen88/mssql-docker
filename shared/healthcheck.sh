#!/usr/bin/env bash
set -eo pipefail

# usage health-check.sh -t <timeout secs> <query>
#   ie: ./health-check.sh -t 5 "SELECT 1"

function main() {
  if [ ! -x "$(command -v sqlcmd)" ]; then
    echo "ERROR: sqlcmd is required for this health check" >&2
    exit 1
  fi

  declare SQLCMDPASSWORD
  SQLCMDPASSWORD=${MSSQL_SA_PASSWORD:-$(< "${MSSQL_SA_PASSWORD_FILE}")}
  export SQLCMDPASSWORD

  debug "Healthcheck query: ${health_check_query}, timeout: ${timeout_secs}."

  set +e
  sqlcmd_output=$(/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -l "${timeout_secs}" -t "${timeout_secs}" -b -Q "${health_check_query}" 2>&1)
  exit_code=$?
  set -e

  debug "sqlcmd output: ${sqlcmd_output}"
  debug "exit code: ${exit_code}"

  exit ${exit_code}
}

function debug() {
  # shellcheck disable=SC2236
  if [ ! -z ${verbose+x} ]; then
    echo "DEBUG: $*"
  fi
}

###############################################################################
# Print usage information
###############################################################################
function usage() {
  >&2 echo "Usage: $0 [-t <secs>] [-v] [<query>]"
  >&2 echo "  -t <seconds>       Timeout in seconds (default of 3)"
  >&2 echo "  -v                 Verbose/debug output"
  >&2 echo "  <query>            Health check query (default: 'SELECT 1')"
}

# Argument Processing
while getopts ":vht:" opt; do
  case "$opt" in
  v)
    verbose=1
    ;;
  h)
    usage
    exit 0
    ;;
  t)
    timeout_secs=${OPTARG}
    if ! [[ ${timeout_secs} =~ ^[0-9]+$ ]]; then
      echo "ERROR: timeout requires a number" >&2
      exit 1
    fi
    ;;
  \?)
    echo "Invalid option: -${OPTARG}" >&2
    exit 1
    ;;
  :)
    echo "Invalid option: -${OPTARG} requires an argument" >&2
    exit 1
    ;;
  esac
done

# shift positional args based on number consumed by getopts
shift $((OPTIND-1))

# remaining argument[s] will be the query, also map in defaults for the other optionals
timeout_secs=${timeout_secs:-3}
health_check_query=${*:-SELECT 1}

# pre-processing done, proceed with main call
main