// Simple server loader for compiled modules
const path = require('path');
const fs = require('fs');

// Load all compiled JS modules in order
const modules = [
    'Common.js',
    'Room.js',
    'Lobby.js',
    'Game.js',
    'FixedGame.js',
    'TrumpGame.js',
    'PercivalGame.js',
    'Player.js',
    'Database_Postgres.js',
    'Statistics_Minimal.js',
    'Bans.js',
    'Rating.js',
    'Commands.js',
    'Tokens.js',
    'Discussions.js',
    'Main.js'
];

// Load each module
modules.forEach(moduleName => {
    const modulePath = path.join(__dirname, moduleName);
    if (fs.existsSync(modulePath)) {
        require(modulePath);
    }
});