#!/usr/bin/env bash
set -euo pipefail

notify() {
    local color="$1"
    local msg="$2"
    local hostname=$(hostname)
    echo "$msg"
    ntfy pub -T "${color}_square" -t "Docker Health on ${hostname}" docker "$msg" >/dev/null 2>&1 || true
}

declare -A compose_projects
declare -a standalone_containers

# Find unhealthy containers
while read -r container; do
    health=$(docker inspect \
        --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
        "$container")

    # Ignore missing health checks and containers still starting
    if [[ "$health" != "unhealthy" ]]; then
        continue
    fi

    project_dir=$(docker inspect \
        --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' \
        "$container")

    if [[ -n "$project_dir" && "$project_dir" != "<no value>" ]]; then
        compose_projects["$project_dir"]+="$container "
    else
        standalone_containers+=("$container")
    fi

done < <(docker ps -q)

# Restart compose projects once each
for project_dir in "${!compose_projects[@]}"; do
    containers="${compose_projects[$project_dir]}"

    notify "orange" "Unhealthy containers in $(basename "$project_dir"): $containers"

    if [[ -f "$project_dir/compose.yaml" ]]; then
        if docker compose \
            --project-directory "$project_dir" \
            up -d --force-recreate; then

            notify "green" "Recovery succeeded: $(basename "$project_dir")"
        else
            notify "red" "Recovery FAILED: $(basename "$project_dir")"
        fi
    else
        notify "black" "Missing compose.yaml in $project_dir"
    fi
done

# Restart standalone containers
for container in "${standalone_containers[@]}"; do
    notify "orange" "Unhealthy standalone container $container"

    if docker restart "$container" >/dev/null; then
        notify "green" "Recovery succeeded: $container"
    else
        notify "red" "Recovery FAILED: $container"
    fi
done

