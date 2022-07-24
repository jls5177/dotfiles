#!/usr/bin/env bash

# import ansi for colored logging
source "${SRC_ROOT}/scripts/lib/ansi"

# Controls verbosity of the script output and logging.
VERBOSE="${VERBOSE:-0}"

# returns the current time in ISO 8601 UTC format for consistency across platforms
log::timestamp() {
  timestamp=$(date -u +"[%Y-%m-%dT%H:%M:%SZ]")
  echo "$timestamp"
}

# returns the string representation for the current log level
log::level::to_string() {
  local LVL="${LVL:-0}"
  local level_str
  case $LVL in
    0)
      level_str=""
      ;;
    1)
      level_str="I"
      ;;
    *)
      level_str="D"
      ;;
  esac
  echo "$level_str"
}

# Log leveled printing, will only print if VERBOSE is greater than LVL
#
# Set $LVL to the threshold needed to print the message (defaults to 0)
# example: LVL=3 log::leveled "Printed if log level is 3 or above"
log::level::log() {
  local LVL="${LVL:-0}"
  if [[ $VERBOSE -ge $LVL ]]; then
    for message; do
      echo "$(log::level::to_string)$(log::timestamp) $message"
    done
  fi
}

# Logs the message at the INFO level
log::echo() {
  echo "${1-}"
  shift
  for message; do
    echo "    $message"
  done
}

log::always() {
  LVL=0 log::level::log "$@"
}

# Logs the message at the INFO level
log::info() {
  LVL=1 log::level::log "$@"
}

# Logs the message at the DEBUG level
log::debug() {
  LVL=2 log::level::log "$@"
}

log::status() {
  echo "+++ $(log::timestamp) ${1-}"
  shift
  for message; do
    echo "    $message"
  done
}

# Logs an error with timestamp prefixed
log::error() {
  ansi --red "!!! $(log::timestamp) ${1-}" >&2
  shift
  for message; do
    ansi --red "    $message" >&2
  done
}

#############
# The following code was adapted from the following Github Gist
# https://gist.github.com/ahendrix/7030300

PROC=$$

# Installs the function to be called when an ERR is caught.
#
# Note: this should be called very early in the shell script.
log::enable_errexit() {
  # trap ERR to provide an error handler whenever a command exits nonzero
  #  this is a more verbose version of set -o errexit
  trap 'log::error::exit' ERR

  # setting errtrace allows our ERR trap handler to be propagated to functions,
  #  expansions and subshells
  set -o errtrace

  # Define USER signal to trigger script exit with return code 30
  trap "exit 30" SIGUSR1
}

# ERR Trap handler to automatically catch any errors
log::error::exit() {
  local err="${PIPESTATUS[@]}"

  # If the shell we are in doesn't have errexit set (common in subshells) then
  # don't dump stacks.
  #set +o | grep -qe "-o errexit" || return

  set +o xtrace
  local code="${1:-1}"
  log::error_exit "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}. '${BASH_COMMAND}' exited with status $err" "${1:-1}" 1
}

# Print out the stack trace
#
# Args:
#   $1 The number of stack frames to skip when printing.
log::error::stacktrace() {
  local stack_skip=${1:-0}
  stack_skip=$((stack_skip + 1))
  if [[ ${#FUNCNAME[@]} -gt $stack_skip ]]; then
    ansi --red "Call stack:" >&2
    local i
    for ((i=1 ; i <= ${#FUNCNAME[@]} - $stack_skip ; i++))
    do
      local frame_no=$((i - 1 + stack_skip))
      ansi --red " $i: ${BASH_SOURCE[$frame_no]}:${BASH_LINENO[$frame_no-1]} ${FUNCNAME[$frame_no]}(...)" >&2
    done
  fi
}

#############

# Log an error and exits
#
# Args:
#   $1 Error message
#   $2 The error code to return (defaults to 1)
#   $3 The number of stack frames to skip when printing. (defaults to 0)
log::error_exit() {
  local message="${1:-}"
  local code=${2:-1}
  local stack_skip="${3:-0}"
  stack_skip=$((stack_skip + 1))

  # print the file and line number that called error_exit
  local source_file=${BASH_SOURCE[$stack_skip]}
  local source_line=${BASH_LINENO[$((stack_skip - 1))]}
  ansi --red "!!! Error in ${source_file}:${source_line}" >&2

  # print the provided error message (if present)
  if [[ -n "${message}" ]]; then
    ansi --red "  ${message}" >&2
  fi

  # print the call stack if 
  if [[ ${VERBOSE} -ge 1 ]]; then
     log::error::stacktrace $stack_skip
  fi

  ansi --red "Exiting with status ${code}" >&2
  
  # Kill the original process if within a subshell
  if [[ "$BASHPID" -ne "$PROC" ]]; then
    ansi --green "Note: exiting from within a subshell, return code will be 30" >&2
    kill -SIGUSR1 $PROC
  fi

  exit $((code + 0))
}
