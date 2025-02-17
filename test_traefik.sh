#!/bin/bash

echo "🛠 Running Traefik Test Suite..."
echo "----------------------------------"

BASE_URL="https://proyectosingenieria.uninorte.edu.co"
CONTAINERS=("bixa-app" "jsonfy-app" "silvy-app")
FOLDER_PATH="/usr/local/apache2/htdocs"

declare -A URL_MAP
declare -A CONTAINER_PATHS

# Function to get files recursively from a container
get_files_from_container() {
    local container=$1
    local folder=$2

    docker exec -it "$container" sh -c "ls -lR $folder 2>/dev/null" | awk '
        BEGIN { dir="" }
        /^\/.*:$/ { gsub(":", "", $0); dir=$0; next }
        /^[^dt]/ { print dir "/" $NF }
    ' | grep -v '/:$'  # Ignore directory listings
}

# Fetch file lists for each container
for container in "${CONTAINERS[@]}"; do
    echo "🔍 Checking files inside $container ($FOLDER_PATH)..."
    FILES=$(get_files_from_container "$container" "$FOLDER_PATH")
    
    for file in $FILES; do
        REL_PATH=${file#"$FOLDER_PATH/"}  # Remove base path
        APP_NAME=${container%-app}        # Extract app name
        URL_PATH="/$APP_NAME/$REL_PATH"
        URL_PATH=${URL_PATH//\/\//\/}  # Fix double slashes in paths

        # Ensure valid file paths before adding to test
        if [[ ! "$REL_PATH" =~ /$ ]]; then
            URL_MAP[$URL_PATH]="$BASE_URL$URL_PATH"
            CONTAINER_PATHS[$URL_PATH]=$file
        fi
    done
done

# Add missing index pages
for container in "${CONTAINERS[@]}"; do
    APP_NAME=${container%-app}
    URL_MAP["/$APP_NAME"]="$BASE_URL/$APP_NAME"
    CONTAINER_PATHS["/$APP_NAME"]="$FOLDER_PATH/index.html"
done

# Run tests
for path in "${!URL_MAP[@]}"; do
    URL=${URL_MAP[$path]}
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    
    if [[ "$RESPONSE" == "200" ]]; then
        echo "✅ $URL - 200 (OK)"
    else
        echo "❌ $URL - $RESPONSE (Failed)"
    fi
done

echo "----------------------------------"
echo "🎯 Test Completed!"
