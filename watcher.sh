check_server() {
  RESPONSE=$(curl -s "$SERVER_URL")
  if [[ "$RESPONSE" == *"$EXPECTED_VERSION"* ]]; then
    echo "Server is up and serving the expected version: $EXPECTED_VERSION"
  else
    echo "Server is either down or not serving the expected version"
  fi
}

# Call the function to check the server
check_server

