FROM node:16-alpine

# Install build dependencies, PostgreSQL client, and coffee-script globally
RUN apk add --no-cache make python3 g++ postgresql-client && \
    npm install -g coffee-script@1.12.7

WORKDIR /app

# Copy package files
COPY package.json package_linux.json package_docker.json ./

# Copy source code
COPY . .

# Build the application using original approach with stub files
RUN mkdir -p release logs && \
    cp package_docker.json release/package.json && \
    cd release && npm install && \
    cd .. && \
    cp server/StatisticsWorkers_Stub.coffee server/StatisticsWorkers.coffee && \
    cp server/Statistics_Simple.coffee server/Statistics.coffee && \
    cat server/Common.coffee server/Room.coffee server/Lobby.coffee server/Game.coffee server/FixedGame.coffee server/TrumpGame.coffee server/PercivalGame.coffee server/Player.coffee server/Database_Postgres.coffee server/StatisticsWorker.coffee server/StatisticsWorkers.coffee server/Statistics.coffee server/Bans.coffee server/Rating.coffee server/Commands.coffee server/Tokens.coffee server/Discussions.coffee server/Main_NoCaptcha.coffee | coffee --compile --stdio > release/Server.js && \
    cp -rf client release/client && \
    cp -rf misc release/misc

# Change to release directory
WORKDIR /app/release

# Expose port
EXPOSE 8080

# Start the application
CMD ["node", "Server.js", "/app/options.json"]