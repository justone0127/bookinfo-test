#!/bin/bash
set -eE

scriptName=$(basename "$0")
usage=$(cat << EOF
Usage: ./$scriptName <repository> <tag> <experiment-namespace>
Environment variables that need to be set:
  BINDIR - Directory containing kubectl
  BRANCH_NAME - Git branch name
EOF
)

function print_and_exit() {
  echo "$usage"
  exit 1
}

# Verify input arguments
if [ "$#" -lt 3 ]; then
  print_and_exit
fi

for a in "$@"; do
  if [ -z "$a" ]; then
    print_and_exit
  fi
done

# Verify env variables
if [ -z "$BINDIR" -o -z "$BRANCH_NAME" ]; then
  print_and_exit
fi

kubectl=$BINDIR/kubectl
if [ ! -d "$BINDIR" -o ! -f "$kubectl" ]; then
  echo "Set environment variable BINDIR to the directory containing kubectl"
  print_and_exit
fi

repository=$1
tag=$2
experimentNamespace=$(echo "$3" | tr '[:upper:]' '[:lower:]')

name=$(echo "$BRANCH_NAME" | tr '[:upper:]' '[:lower:]')
version=$name

templateFilesDir="kube/experiment/templates"
templateFiles=$(ls $templateFilesDir/*.yaml)
for f in "${templateFiles[@]}"; do
  sed -i".bak" -e "s;<image-registry>/\(examples-bookinfo-.*\):<image-tag>;$repository:\1-$tag;g" \
  -e "s;<experiment-namespace>;$experimentNamespace;g" \
  -e "s;<version>;$version;g" $f
done

echo "Applying the following manifests"
echo "============================================="
cat $templateFiles
echo "============================================="

set +eE
$kubectl apply -R -f $templateFilesDir
if [ ! $? -eq 0 ]; then
  echo "kubectl apply failed, cleaning up the installed manifests"
  $kubectl delete -R -f $templateFilesDir
  exit 1
fi
