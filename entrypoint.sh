#!/bin/bash
set -euo pipefail

PG_TARBALL_URL="${1:-https://pgedge-download.s3.amazonaws.com/REPO/pg17-17.5-1-amd.tgz}"
PG_TARBALL_NAME="$(basename "$PG_TARBALL_URL")"
PG_NAME_BASE="${PG_TARBALL_NAME%.tar.gz}"
PG_NAME_BASE="${PG_NAME_BASE%.tgz}"

PG_DIR="/opt/${PG_NAME_BASE}"
SBOM_DIR="/opt/pg_sbom"

echo "📥 Downloading PostgreSQL tarball from $PG_TARBALL_URL"
curl -fsSL "$PG_TARBALL_URL" -o "$PG_TARBALL_NAME"

echo "📦 Extracting tarball to $PG_DIR"
mkdir -p "$PG_DIR"
tar -xzf "$PG_TARBALL_NAME" -C "$PG_DIR" --strip-components=1

echo "🧾 Generating SBOMs in $SBOM_DIR"
mkdir -p "$SBOM_DIR"

syft "dir:$PG_DIR" --output "cyclonedx-json=$SBOM_DIR/sbom-${PG_NAME_BASE}-cyclonedx.json"
syft "dir:$PG_DIR" --output "spdx-json=$SBOM_DIR/sbom-${PG_NAME_BASE}-spdx.json"

echo "🔍 Running Grype vulnerability scan..."
grype "sbom:$SBOM_DIR/sbom-${PG_NAME_BASE}-cyclonedx.json" -o table > "$SBOM_DIR/vuln-${PG_NAME_BASE}.txt"

jq '{
  "$schema": ."$schema",
  "bomFormat": .bomFormat,
  "specVersion": .specVersion,
  "serialNumber": .serialNumber,
  "version": .version,
  "metadata": .metadata,
  "components": .components
}' "$SBOM_DIR/sbom-${PG_NAME_BASE}-cyclonedx.json" > "$SBOM_DIR/sbom-${PG_NAME_BASE}-cve.json"

jq '{
  "SPDXID": .SPDXID,
  "spdxVersion": .spdxVersion,
  "name": .name,
  "dataLicense": .dataLicense,
  "documentNamespace": .documentNamespace,
  "creationInfo": .creationInfo,
  "packages": [.packages[] | {
    "name": .name,
    "SPDXID": .SPDXID,
    "versionInfo": .versionInfo,
    "licenseConcluded": .licenseConcluded,
    "licenseDeclared": .licenseDeclared,
    "copyrightText": .copyrightText,
    "supplier": .supplier
  }]
}' "$SBOM_DIR/sbom-${PG_NAME_BASE}-spdx.json" > "$SBOM_DIR/sbom-${PG_NAME_BASE}-license.json"

echo "✅ Done. Files generated in $SBOM_DIR"

