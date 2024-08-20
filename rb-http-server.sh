#!/bin/bash

PORT=8080
DATA_DIR="./data"

# Ensure data directory exists
mkdir -p "$DATA_DIR"

handle_request() {
    read -r request_line
    read -r host_header
    content_length=0

    # Read headers
    while read -r header; do
        header=$(echo "$header" | tr -d '\r\n')
        if [[ -z "$header" ]]; then
            break
        fi
        if [[ "$header" =~ ^Content-Length:\ (.*)$ ]]; then
            content_length="${BASH_REMATCH[1]}"
        fi
    done

    # Read body if present
    if [[ $content_length -gt 0 ]]; then
        body=$(dd bs=1 count=$content_length 2>/dev/null)
    fi

    # Parse request
    method=$(echo "$request_line" | cut -d' ' -f1)
    path=$(echo "$request_line" | cut -d' ' -f2)
    id=$(echo "$path" | cut -d'/' -f2)

    case "$method" in
        GET)
            if [[ -f "$DATA_DIR/$id" ]]; then
                echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n$(cat "$DATA_DIR/$id")"
            else
                echo -e "HTTP/1.1 404 Not Found\r\n\r\nResource not found."
            fi
            ;;
        POST)
            echo "$body" > "$DATA_DIR/$id"
            echo -e "HTTP/1.1 201 Created\r\n\r\nResource created."
            ;;
        PUT)
            echo "$body" > "$DATA_DIR/$id"
            echo -e "HTTP/1.1 200 OK\r\n\r\nResource updated."
            ;;
        DELETE)
            if [[ -f "$DATA_DIR/$id" ]]; then
                rm "$DATA_DIR/$id"
                echo -e "HTTP/1.1 200 OK\r\n\r\nResource deleted."
            else
                echo -e "HTTP/1.1 404 Not Found\r\n\r\nResource not found."
            fi
            ;;
        *)
            echo -e "HTTP/1.1 405 Method Not Allowed\r\n\r\nMethod not allowed."
            ;;
    esac
}

echo "Starting server on port $PORT..."
while true; do
    nc -l -p "$PORT" -c handle_request
done
