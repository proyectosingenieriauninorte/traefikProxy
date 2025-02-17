#!/bin/bash

echo "🛠 Running Traefik Test Suite..."
echo "----------------------------------"

# List of test URLs
URLS=(
    "https://proyectosingenieria.uninorte.edu.co/"
    "https://proyectosingenieria.uninorte.edu.co/bixa"
    "https://proyectosingenieria.uninorte.edu.co/bixa/main.css"
    "https://proyectosingenieria.uninorte.edu.co/bixa/main.js"
    "https://proyectosingenieria.uninorte.edu.co/jsonfy"
    "https://proyectosingenieria.uninorte.edu.co/jsonfy/styles/index.css"
    "https://proyectosingenieria.uninorte.edu.co/silvy"
    "https://proyectosingenieria.uninorte.edu.co/silvy/estilo.css"
)

# Function to check URLs via curl
check_url() {
    response=$(curl -s -o /dev/null -w "%{http_code} %{content_type}\n" "$1")
    status_code=$(echo "$response" | awk '{print $1}')
    content_type=$(echo "$response" | awk '{$1=""; print $0}' | xargs)

    if [ "$status_code" == "200" ]; then
        echo "✅ $1 - $status_code ($content_type)"
    else
        echo "❌ $1 - $status_code (Failed)"
    fi
}

# Run tests for URLs
for url in "${URLS[@]}"; do
    check_url "$url"
done

echo "----------------------------------"
echo "🔍 Checking Files Inside Containers..."

# Verify files exist inside each container
check_files() {
    container=$1
    path=$2
    echo "🛠 Checking $container ($path)"
    docker exec -it "$container" ls -lhR "$path"
}

check_files "bixa-app" "/usr/local/apache2/htdocs/"
check_files "jsonfy-app" "/usr/local/apache2/htdocs/"
check_files "silvy-app" "/usr/local/apache2/htdocs/"

echo "----------------------------------"
echo "🔍 Checking MIME Types of Assets..."

# Function to check actual HTTP headers
check_mime_type() {
    url=$1
    response=$(curl -sI "$url" | grep -i "Content-Type")
    echo "$response - $url"
}

check_mime_type "https://proyectosingenieria.uninorte.edu.co/bixa/main.css"
check_mime_type "https://proyectosingenieria.uninorte.edu.co/bixa/main.js"

echo "----------------------------------"
echo "🔍 Extracting Asset URLs from index.html..."

# Function to extract and validate asset URLs from HTML
extract_assets() {
    url=$1
    echo "🔍 Checking asset links in $url"
    assets=$(curl -s "$url" | grep -oE 'href="[^"]+"|src="[^"]+"' | cut -d'"' -f2)

    for asset in $assets; do
        full_url="https://proyectosingenieria.uninorte.edu.co$asset"
        check_url "$full_url"
    done
}

extract_assets "https://proyectosingenieria.uninorte.edu.co/bixa"

echo "----------------------------------"
echo "🎯 Test Completed!"
