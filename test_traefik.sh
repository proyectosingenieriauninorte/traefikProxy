#!/bin/bash

# List of test URLs
URLS=(
    "https://proyectosingenieria.uninorte.edu.co/"
    "https://proyectosingenieria.uninorte.edu.co/bixa"
    "https://proyectosingenieria.uninorte.edu.co/bixa/main.css"
    "https://proyectosingenieria.uninorte.edu.co/bixa/main.js"
    "https://proyectosingenieria.uninorte.edu.co/bixa/favicon.ico"
    "https://proyectosingenieria.uninorte.edu.co/jsonfy"
    "https://proyectosingenieria.uninorte.edu.co/jsonfy/main.css"
    "https://proyectosingenieria.uninorte.edu.co/silvy"
    "https://proyectosingenieria.uninorte.edu.co/silvy/main.css"
)

echo "🛠 Running Traefik Test Suite..."
echo "----------------------------------"

# Function to test each URL
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

# Run tests
for url in "${URLS[@]}"; do
    check_url "$url"
done

echo "----------------------------------"
echo "🎯 Test Completed!"
