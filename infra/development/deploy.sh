#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: deploy.sh <bundle-directory> <image-archive> <image-tag>" >&2
  exit 2
fi

bundle_directory=$1
image_archive=$2
image_tag=$3
deploy_root=${MEMORA_DEPLOY_ROOT:-/home/kaveesha/Memora}
environment_file=${MEMORA_ENV_FILE:-/home/kaveesha/.config/memora/development.env}
compose_file="$deploy_root/compose.yaml"

for required_file in "$bundle_directory/compose.yaml" "$bundle_directory/Caddyfile" "$image_archive" "$environment_file"; do
  if [[ ! -f "$required_file" ]]; then
    echo "required deployment file is missing: $required_file" >&2
    exit 1
  fi
done

install -d -m 700 "$deploy_root"
install -m 600 "$bundle_directory/compose.yaml" "$compose_file"
install -m 644 "$bundle_directory/Caddyfile" "$deploy_root/Caddyfile"

gzip -dc "$image_archive" | docker load

export MEMORA_IMAGE_TAG="$image_tag"
export MEMORA_ENV_FILE="$environment_file"
export MEMORA_DEV_DOMAIN
MEMORA_DEV_DOMAIN=$(sed -n 's/^MEMORA_DEV_DOMAIN=//p' "$environment_file" | tail -n 1)
if [[ -z "$MEMORA_DEV_DOMAIN" ]]; then
  echo "MEMORA_DEV_DOMAIN is missing from $environment_file" >&2
  exit 1
fi

docker compose --project-name memora-development --env-file "$environment_file" -f "$compose_file" run --rm --no-deps api \
  python -m alembic -c alembic.ini upgrade head
docker compose --project-name memora-development --env-file "$environment_file" -f "$compose_file" up -d --wait --remove-orphans

curl --fail --silent --show-error --retry 6 --retry-delay 5 \
  "https://${MEMORA_DEV_DOMAIN}/health/ready" >/dev/null

printf '%s\n' "$image_tag" >"$deploy_root/current-image"
echo "Memora development deployment is healthy at https://${MEMORA_DEV_DOMAIN}"
