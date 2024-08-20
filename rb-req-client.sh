#!/bin/bash
# A raw-bash HTTP request client

perform_request() {
    local method="$1"
    local url="$2"
    local data="$3"
    
    # Use awk to extract the host and path from the URL
    # -F/ sets the field separator to '/'
    # '{print $3}' prints the third field (the host)
    local host=$(echo "$url" | awk -F/ '{print $3}')
    
    # '{print "/" $4}' prints a '/' followed by the fourth field (the path)
    local path=$(echo "$url" | awk -F/ '{print "/" $4}')

    # Open a TCP connection to the host on port 80
    # 3<>/dev/tcp/$host/80 opens a bidirectional connection
    # 3 is the file descriptor for this connection
    exec 3<>/dev/tcp/"$host"/80

    # Send the HTTP request
    # -e enables interpretation of backslash escapes
    # >&3 redirects the output to file descriptor 3 (our TCP connection)
    echo -e "$method $path HTTP/1.1\r
Host: $host\r
Connection: close\r
Content-Length: ${#data}\r
\r
$data" >&3

    # Read the response
    # <&3 redirects input from file descriptor 3
    cat <&3
    
    # Close the TCP connection
    exec 3>&-
}

# GET request
get_request() {
    perform_request "GET" "$1" ""
}

# POST request
post_request() {
    perform_request "POST" "$1" "$2"
}

# PUT request
put_request() {
    perform_request "PUT" "$1" "$2"
}

# DELETE request
delete_request() {
    perform_request "DELETE" "$1" ""
}

# OPTIONS request
options_request() {
    perform_request "OPTIONS" "$1" ""
}

# Usage examples
# get_request "http://example.com"
# post_request "http://example.com/api" "key1=value1&key2=value2"
# put_request "http://example.com/api/resource" "updated_data"
# delete_request "http://example.com/api/resource"
# options_request "http://example.com"
