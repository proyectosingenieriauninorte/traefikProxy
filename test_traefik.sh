#!/bin/bash

echo "🛠 Running Traefik Test Suite..."
echo "----------------------------------"

# List of test URLs
URLS=(
    "https://proyectosingenieria.uninorte.edu.co/"
    "https://proyectosingenieria.uninorte.edu.co/bixa"
    "https://proyectosingenieria.uninorte.edu.co/bixa/main.css"
    "https://proyectosingenieria.uninorte.edu.co/bixa/main.js"
    "https://proyectosingenieria.uninorte.edu.co/bixa/favicon.ico"
    "https://proyectosingenieria.uninorte.edu.co/jsonfy"
    "https://proyectosingenieria.uninorte.edu.co/jsonfy/styles/main.css"
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
    docker exec -it "$container" ls -lh "$path"
}

check_files "bixa-app" "/usr/local/apache2/htdocs/"
check_files "jsonfy-app" "/usr/local/apache2/htdocs/"
check_files "silvy-app" "/usr/local/apache2/htdocs/"

echo "----------------------------------"
echo "🔍 Testing Direct Access from Traefik Container..."

# Test file access inside Traefik container
docker exec -it traefikproxy-traefik-1 sh -c "
    echo 'Checking direct file access from Traefik...'
    wget -qO- http://172.17.0.1:5002/main.css
    wget -qO- http://172.17.0.1:5003/styles/main.css
    wget -qO- http://172.17.0.1:5004/estilo.css
"

echo "----------------------------------"
echo "🔍 Checking Apache/Nginx MIME Type Configuration..."

# Check Apache/Nginx MIME type settings
check_mime() {
    container=$1
    echo "🛠 Checking MIME types in $container"
    docker exec -it "$container" cat /usr/local/apache2/conf/httpd.conf | grep "AddType"
}

check_mime "bixa-app"
check_mime "jsonfy-app"
check_mime "silvy-app"

echo "----------------------------------"
echo "🎯 Test Completed!"
