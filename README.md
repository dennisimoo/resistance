# The Resistance - Online Game

An online multiplayer implementation of the popular social deduction board game "The Resistance" built with Node.js, CoffeeScript, and PostgreSQL.

## 🚀 Quick Start with Docker (Recommended)

The easiest way to run The Resistance is using Docker and Docker Compose:

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Installation

1. **Clone or download the project**
2. **Navigate to the project directory**
3. **Start the application:**
   ```bash
   docker-compose up -d
   ```

4. **Access the game:**
   - Open your browser to [http://localhost:8080](http://localhost:8080)
   - Register a new account or login with existing credentials
   - Start playing!

### What's Included

The Docker setup automatically provides:
- **Web Application** running on port 8080
- **PostgreSQL Database** with all required tables and sample data
- **Persistent data storage** for game records and user accounts
- **Automatic database initialization** on first run

### Docker Commands

```bash
# Start the game
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the game
docker-compose down

# Rebuild after code changes
docker-compose down && docker-compose build && docker-compose up -d
```

## 🛠️ Manual Installation (Linux/PostgreSQL)

If you prefer to run without Docker:

### Prerequisites

- [Node.js](https://nodejs.org/en/) (v16+ recommended)
- [PostgreSQL](https://www.postgresql.org/download/)
- [CoffeeScript](https://coffeescript.org/): `npm install -g coffee-script`

### Database Setup

1. **Create a PostgreSQL database:**
   ```bash
   sudo su postgres
   psql
   postgres=# CREATE USER resistance_user WITH PASSWORD 'resistance_pass';
   postgres=# CREATE DATABASE resistance OWNER resistance_user;
   postgres=# \q
   exit
   ```

2. **Initialize the database schema:**
   ```bash
   psql -h localhost -U resistance_user -d resistance -f misc/recreatedb_pg.sql
   ```

### Application Setup

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Create configuration file** (copy from `sample_options.json`):
   ```json
   {
     "port": 8080,
     "db_connection_string": "postgres://resistance_user:resistance_pass@localhost/resistance",
     "admin": [],
     "mods": []
   }
   ```

3. **Build the application:**
   ```bash
   make
   ```

4. **Start the server:**
   ```bash
   node release/Server.js options.json
   ```

5. **Access the game** at [http://localhost:8080](http://localhost:8080)

## 🎮 Game Features

- **Full Resistance gameplay** with all standard rules
- **Multiple game variants** including:
  - Standard Resistance
  - Avalon mode with Merlin/Percival
  - Lady of the Lake
  - Custom role combinations
- **Real-time multiplayer** with WebSocket support
- **User accounts** with persistent statistics
- **Spectator mode** for watching games
- **Chat system** with game-specific channels
- **Rating system** for competitive play
- **Moderation tools** for game administrators

## 🔧 Configuration Options

The `options.json` file supports these settings:

```json
{
  "port": 8080,
  "db_connection_string": "postgres://user:pass@host/database",
  "admin": ["admin_username"],
  "mods": ["moderator_username"],
  "allow_registration": true
}
```

## 🐳 Deployment

### Dokploy/Cloud Deployment

1. Upload your project files to your deployment platform
2. Use the included `docker-compose.yml` for container orchestration
3. Ensure environment variables are set if needed
4. The application will automatically initialize the database on first run

### Production Considerations

- Use strong passwords for database connections
- Configure firewall rules to restrict database access
- Consider using environment variables for sensitive configuration
- Set up SSL/HTTPS termination at your reverse proxy
- Monitor logs for any issues: `docker-compose logs -f`

## 🎯 Game Rules

The Resistance is a social deduction game where:
- **Resistance members** try to complete missions
- **Spies** try to sabotage missions without being discovered
- Players vote on mission teams and mission outcomes
- Communication and deduction are key to victory

## 🔧 Development

### Architecture Overview

- **Frontend**: Vanilla JavaScript with jQuery and Bootstrap
- **Backend**: Node.js with Express and CoffeeScript
- **Database**: PostgreSQL with connection pooling
- **Real-time**: Long polling for live updates

### Key Components

- `server/Main.coffee` - Main server application and routing
- `server/Game.coffee` - Core game logic and state management
- `server/Lobby.coffee` - Player matchmaking and room management
- `server/Player.coffee` - Player state and message handling
- `client/` - Static web assets and frontend code

### Testing

- Use `misc/Bot.coffee` to simulate multiple players
- See `Test.coffee` for unit testing examples
- Manual testing with multiple browser windows

## 📝 Changes from Original

This Docker-ready version includes:

- ✅ **Removed CAPTCHA dependency** for easier deployment
- ✅ **Docker containerization** with compose setup
- ✅ **Simplified Statistics module** (removed webworker-threads dependency)
- ✅ **Production-ready configuration** files
- ✅ **Automatic database initialization**
- ✅ **Updated documentation** with Docker instructions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with multiple players
5. Submit a pull request

## 📄 License

See the original license file for terms and conditions.

## 🎉 Credits

Based on the original implementation with enhancements for modern deployment and Docker support.