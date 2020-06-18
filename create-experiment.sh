#!/bin/bash
set -eE

scriptName=$(basename "$0")
usage=$(cat << EOF
Usage: ./$scriptName <experiment-name> <baseline-namespace> <experiment-namespace> <service1> <service2>...<serviceN>
Environment variables that need to be set:
  BINDIR - Directory containing aspenctl
  TOKEN - Aspen Mesh token for the cluster
EOF
)

function print_and_exit() {
  echo "$usage"
  exit 1
}

# Verify input arguments
if [ "$#" -lt 4 ]; then
  print_and_exit
fi

for a in "$@"; do
  if [ -z "$a" ]; then
    print_and_exit
  fi
done

# Verify env variables
if [ -z "$BINDIR" -o -z "$TOKEN" ]; then
  print_and_exit
fi

aspenctl=$BINDIR/aspenctl
if [ ! -d "$BINDIR" -o ! -f "$aspenctl" ]; then
  echo "Set environment variable BINDIR to the directory containing aspenctl"
  print_and_exit
fi

experimentName=$(echo "$1" | tr '[:upper:]' '[:lower:]')
baselineNamespace=$(echo "$2" | tr '[:upper:]' '[:lower:]')
experimentNamespace=$(echo "$3" | tr '[:upper:]' '[:lower:]')
services=("${@:4}")

aspenctlCmd="$aspenctl --token $TOKEN ensure experiment --name $experimentName"
for s in "${services[@]}"; do
  cs=$(echo "$s" | tr '[:upper:]' '[:lower:]')
  aspenctlCmd="$aspenctlCmd --set-service \"$baselineNamespace/$cs:$experimentNamespace/$cs\""
done
echo $aspenctlCmd
$aspenctlCmd
