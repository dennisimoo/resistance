#!/bin/sh
set -e

mkdir -p release logs

# Copy package and install deps
cp package_docker.json release/package.json
cd release
npm install
cd ..

# Convert each CoffeeScript file to JavaScript individually
echo "Converting CoffeeScript files..."

# Convert files one by one and combine into single Server.js
echo "// Generated server file" > release/Server.js

for file in Common Room Lobby Game FixedGame TrumpGame PercivalGame Player Database_Postgres Bans Rating Commands Tokens Discussions; do
    echo "Processing $file..."
    coffee -c server/$file.coffee
    cat server/$file.js >> release/Server.js
    rm server/$file.js
    echo "" >> release/Server.js
done

# Add simple statistics class directly in JavaScript
cat >> release/Server.js << 'EOF'

// Simple Statistics class for Docker
var Statistics = (function() {
    function Statistics(db) {
        this.db = db;
        this.stats = {
            activeplayers: [],
            leaderboard: [],
            recentgames: [],
            winrates: {},
            activity: {},
            ratings: [],
            ratings2: []
        };
    }

    Statistics.prototype.refresh = function() {
        console.log("Statistics refresh disabled in Docker deployment");
    };

    Statistics.prototype.respond = function(player) {
        return player.send({cmd: "stats", data: this.stats});
    };

    return Statistics;
})();

EOF

# Add Main.js
echo "Processing Main..."
coffee -c server/Main.coffee
cat server/Main.js >> release/Server.js
rm server/Main.js

# Copy client files
cp -rf client release/client

echo "Build complete!"