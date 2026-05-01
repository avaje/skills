#!/bin/bash
#
# Generates flattened reference bundles for avaje skills
# from source guides in sibling repos (avaje-nima, avaje-inject, avaje-config, avaje-jsonb).
#
# By default, looks for repos as siblings of this directory.
# Override with: AVAJE_DIR=/path/to/avaje ./generate-references.sh
#
# Usage:
#   ./generate-references.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AVAJE_DIR="${AVAJE_DIR:-$SCRIPT_DIR/..}"

NIMA_GUIDES="$AVAJE_DIR/avaje-nima/docs/guides"
INJECT_GUIDES="$AVAJE_DIR/avaje-inject/docs/guides"
CONFIG_GUIDES="$AVAJE_DIR/avaje-config/docs/guides"
JSONB_GUIDES="$AVAJE_DIR/avaje-jsonb/docs/guides"
LOGGER_GUIDES="$AVAJE_DIR/avaje-simple-logger/docs/guides"

# Verify repos exist
for dir in "$NIMA_GUIDES" "$INJECT_GUIDES" "$CONFIG_GUIDES" "$JSONB_GUIDES" "$LOGGER_GUIDES"; do
  if [ ! -d "$dir" ]; then
    echo "Error: guides directory not found at $dir" >&2
    echo "Set AVAJE_DIR to the parent of your avaje repo checkouts:" >&2
    echo "  AVAJE_DIR=/path/to/avaje ./generate-references.sh" >&2
    exit 1
  fi
done

# Generate a flattened bundle from one or more source guides.
#   generate_bundle <output-file> <title> <guides-dir> <guide1> [<guides-dir2> <guide2>] ...
#
# Arguments alternate: <guides-dir> <guide-file> <guides-dir> <guide-file> ...
generate_bundle() {
  local output_file="$1"
  local title="$2"
  shift 2

  {
    echo "# Avaje Bundle — ${title} (Flattened)"
    echo ""
    echo "> Flattened bundle. Content from source markdown guides is inlined below."
    while [ $# -ge 2 ]; do
      local dir="$1"
      local guide="$2"
      shift 2
      local guide_file="$dir/$guide"
      if [ ! -f "$guide_file" ]; then
        echo "Warning: guide not found: $guide_file" >&2
        continue
      fi
      echo ""
      echo "---"
      echo ""
      local repo_name=$(echo "$dir" | sed 's|.*/avaje-||; s|/docs/guides||')
      echo "## Source: \`${repo_name}/${guide}\`"
      echo ""
      cat "$guide_file"
    done
  } > "$output_file"

  echo "  Generated $(basename "$output_file") ($(wc -c < "$output_file" | tr -d ' ') bytes)"
}

# ──────────────────────────────────────────────
# avaje-nima skill
# ──────────────────────────────────────────────
NIMA_REFS="$SCRIPT_DIR/avaje-nima/references"
mkdir -p "$NIMA_REFS"

echo "Generating avaje-nima skill references ..."

generate_bundle "$NIMA_REFS/setup.md" "Setup" \
  "$NIMA_GUIDES" archetype-getting-started.md \
  "$NIMA_GUIDES" multi-module-architecture.md

generate_bundle "$NIMA_REFS/controllers.md" "Controllers" \
  "$NIMA_GUIDES" controller-basics.md \
  "$NIMA_GUIDES" filters.md \
  "$NIMA_GUIDES" exception-handling.md \
  "$NIMA_GUIDES" add-global-exception-handler.md \
  "$NIMA_GUIDES" validation.md

generate_bundle "$NIMA_REFS/dependency-injection.md" "Dependency Injection" \
  "$NIMA_GUIDES" dependency-injection.md \
  "$INJECT_GUIDES" creating-beans.md \
  "$INJECT_GUIDES" dependency-injection.md \
  "$INJECT_GUIDES" factory-methods.md \
  "$INJECT_GUIDES" qualifiers.md \
  "$INJECT_GUIDES" lifecycle-hooks.md

generate_bundle "$NIMA_REFS/configuration.md" "Configuration" \
  "$CONFIG_GUIDES" getting-started.md \
  "$CONFIG_GUIDES" default-values.md \
  "$CONFIG_GUIDES" profiles.md \
  "$CONFIG_GUIDES" environment-variables.md \
  "$CONFIG_GUIDES" change-listeners.md \
  "$CONFIG_GUIDES" cloud-integration.md

generate_bundle "$NIMA_REFS/json.md" "JSON" \
  "$JSONB_GUIDES" basic-usage.md \
  "$JSONB_GUIDES" custom-adapters.md \
  "$JSONB_GUIDES" property-mapping.md \
  "$JSONB_GUIDES" polymorphic-types.md \
  "$JSONB_GUIDES" streaming.md

generate_bundle "$NIMA_REFS/testing.md" "Testing" \
  "$NIMA_GUIDES" testing.md \
  "$NIMA_GUIDES" add-controller-test.md \
  "$INJECT_GUIDES" testing.md \
  "$CONFIG_GUIDES" testing.md \
  "$JSONB_GUIDES" testing.md

generate_bundle "$NIMA_REFS/deployment.md" "Deployment" \
  "$NIMA_GUIDES" add-jvm-docker-jib.md \
  "$NIMA_GUIDES" add-native-docker-jib.md \
  "$NIMA_GUIDES" native-image.md \
  "$NIMA_GUIDES" deployment.md \
  "$NIMA_GUIDES" troubleshooting.md

# ──────────────────────────────────────────────
# avaje-inject skill (standalone)
# ──────────────────────────────────────────────
INJECT_REFS="$SCRIPT_DIR/avaje-inject/references"
mkdir -p "$INJECT_REFS"

echo ""
echo "Generating avaje-inject skill references ..."

generate_bundle "$INJECT_REFS/setup.md" "Setup" \
  "$INJECT_GUIDES" creating-beans.md

generate_bundle "$INJECT_REFS/dependency-injection.md" "Dependency Injection" \
  "$INJECT_GUIDES" creating-beans.md \
  "$INJECT_GUIDES" dependency-injection.md \
  "$INJECT_GUIDES" factory-methods.md \
  "$INJECT_GUIDES" qualifiers.md \
  "$INJECT_GUIDES" lifecycle-hooks.md \
  "$INJECT_GUIDES" native-image.md

generate_bundle "$INJECT_REFS/configuration.md" "Configuration" \
  "$CONFIG_GUIDES" getting-started.md \
  "$CONFIG_GUIDES" default-values.md \
  "$CONFIG_GUIDES" profiles.md \
  "$CONFIG_GUIDES" environment-variables.md \
  "$CONFIG_GUIDES" change-listeners.md \
  "$CONFIG_GUIDES" cloud-integration.md \
  "$CONFIG_GUIDES" native-image.md

generate_bundle "$INJECT_REFS/testing.md" "Testing" \
  "$INJECT_GUIDES" testing.md \
  "$INJECT_GUIDES" testing-postgres-ebean.md \
  "$INJECT_GUIDES" testing-localstack.md \
  "$INJECT_GUIDES" testing-avaje-inject-vs-spring.md \
  "$CONFIG_GUIDES" testing.md

# ──────────────────────────────────────────────
# avaje-config skill (standalone)
# ──────────────────────────────────────────────
CONFIG_REFS="$SCRIPT_DIR/avaje-config/references"
mkdir -p "$CONFIG_REFS"

echo ""
echo "Generating avaje-config skill references ..."

generate_bundle "$CONFIG_REFS/setup.md" "Setup" \
  "$CONFIG_GUIDES" getting-started.md \
  "$CONFIG_GUIDES" adding-avaje-config.md \
  "$CONFIG_GUIDES" default-values.md

generate_bundle "$CONFIG_REFS/advanced.md" "Advanced" \
  "$CONFIG_GUIDES" profiles.md \
  "$CONFIG_GUIDES" environment-variables.md \
  "$CONFIG_GUIDES" change-listeners.md \
  "$CONFIG_GUIDES" cloud-integration.md \
  "$CONFIG_GUIDES" native-image.md

generate_bundle "$CONFIG_REFS/testing.md" "Testing" \
  "$CONFIG_GUIDES" testing.md \
  "$CONFIG_GUIDES" troubleshooting.md

# ──────────────────────────────────────────────
# avaje-jsonb skill (standalone)
# ──────────────────────────────────────────────
JSONB_REFS="$SCRIPT_DIR/avaje-jsonb/references"
mkdir -p "$JSONB_REFS"

echo ""
echo "Generating avaje-jsonb skill references ..."

generate_bundle "$JSONB_REFS/usage.md" "Usage" \
  "$JSONB_GUIDES" basic-usage.md \
  "$JSONB_GUIDES" property-mapping.md

generate_bundle "$JSONB_REFS/advanced.md" "Advanced" \
  "$JSONB_GUIDES" custom-adapters.md \
  "$JSONB_GUIDES" polymorphic-types.md \
  "$JSONB_GUIDES" streaming.md

generate_bundle "$JSONB_REFS/testing.md" "Testing" \
  "$JSONB_GUIDES" testing.md

# ──────────────────────────────────────────────
# avaje-simple-logger skill
# ──────────────────────────────────────────────
LOGGER_REFS="$SCRIPT_DIR/avaje-simple-logger/references"
mkdir -p "$LOGGER_REFS"

echo ""
echo "Generating avaje-simple-logger skill references ..."

generate_bundle "$LOGGER_REFS/setup.md" "Setup" \
  "$LOGGER_GUIDES" add-avaje-simple-logger-to-maven-project.md

generate_bundle "$LOGGER_REFS/aws-appconfig.md" "AWS AppConfig" \
  "$LOGGER_GUIDES" add-aws-appconfig-to-project.md

echo ""
echo "Done. References written to avaje-nima/ avaje-inject/ avaje-config/ avaje-jsonb/ avaje-simple-logger/"
