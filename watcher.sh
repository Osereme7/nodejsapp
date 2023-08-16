SERVER_URL="http://nodejsapp@aws.com"
EXPECTED_VERSION="1.0.0"

check_server() {
  RESPONSE=$(curl -s "$SERVER_URL")
  if [[ "$RESPONSE" == *"$EXPECTED_VERSION"* ]]; then
    echo "Node.js application is up and serving the expected version: $EXPECTED_VERSION"
  else
    echo "Node.js application is either down or not serving the expected version"
  fi
}


check_server


