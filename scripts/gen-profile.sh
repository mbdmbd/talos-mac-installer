#!/usr/bin/env bash
# Render profile.yaml.tmpl for a given output kind.
#   Usage: OUTPUT_KIND=iso OUTPUT_FORMAT=raw scripts/gen-profile.sh > profile.iso.yaml
#          OUTPUT_KIND=installer OUTPUT_FORMAT="" scripts/gen-profile.sh > profile.installer.yaml
# Required env: REGISTRY, ARCH, TALOS_VERSION.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${OUTPUT_KIND:?set OUTPUT_KIND (iso|installer)}"
: "${OUTPUT_FORMAT:=}"          # iso wants "raw"; installer wants empty
: "${REGISTRY:?}" "${ARCH:?}" "${TALOS_VERSION:?}"

export OUTPUT_KIND OUTPUT_FORMAT REGISTRY ARCH TALOS_VERSION

# outFormat only applies to disk-image kinds (iso uses "raw"); for kind=installer it
# must be absent — an empty value makes the imager error "unknown output format".
envsubst < "${here}/profile.yaml.tmpl" | sed -E '/^[[:space:]]*outFormat:[[:space:]]*$/d'
