#!/bin/sh
set -e

mkdir -p release logs

# Copy package and install deps
cp package_docker.json release/package.json
cd release
npm install
cd ..

# Create a simple server that loads the original combined approach
# First create the working version without problematic modules
echo "// Auto-generated server for Docker" > release/Server.js

# Compile each file separately and load them in order
for file in Common Room Lobby Game FixedGame TrumpGame PercivalGame Player Database_Postgres Bans Rating Commands Tokens Discussions; do
    echo "Loading $file..."
    coffee -c server/$file.coffee
    cat server/$file.js >> release/Server.js
    rm server/$file.js
done

# Add our minimal statistics
coffee -c server/Statistics_Minimal.coffee
cat server/Statistics_Minimal.js >> release/Server.js
rm server/Statistics_Minimal.js

# Finally add Main
coffee -c server/Main.coffee
cat server/Main.js >> release/Server.js
rm server/Main.js

# Copy client files
cp -rf client release/client

echo "Build complete!"