# Threads = require 'webworker-threads'

class Statistics
    constructor: (@db) ->
        @stats = {}
        @tables = {}
        # setInterval (=> @refresh()), 4 * 60 * 60 * 1000
        # @statsWorkers = new StatisticsWorkers()
        # @statsWorker = @statsWorkers.newWorker()
        # @statsWorker.onmessage = (e) =>
        #     @tables = e.data
        #     @stats =
        #         activeplayers: @getActivePlayers(@tables)
        #         leaderboard: @getLeaderboard(@tables)
        #         recentgames: @getRecentGames(@tables)
        #         winrates: @getWinRates(@tables)
        #         activity: @getActivity(@tables)
        #         ratings: @getRatings(@tables)
        #         ratings2: @getRatings2(@tables)
        #     @tables = e.data.tables

        # Initialize with empty stats for Docker deployment
        @stats =
            activeplayers: []
            leaderboard: []
            recentgames: []
            winrates: {}
            activity: {}
            ratings: []
            ratings2: []

    refresh: () ->
        # Disabled for Docker deployment
        console.log "Statistics refresh disabled in Docker deployment"
        # @statsWorker.postMessage @tables

    getActivePlayers: (tables) ->
        # Stub implementation
        return []

    getLeaderboard: (tables) ->
        # Stub implementation
        return []

    getRecentGames: (tables) ->
        # Stub implementation
        return []

    getWinRates: (tables) ->
        # Stub implementation
        return {}

    getActivity: (tables) ->
        # Stub implementation
        return {}

    getRatings: (tables) ->
        # Stub implementation
        return []

    getRatings2: (tables) ->
        # Stub implementation
        return []

    respond: (player) ->
        return player.send cmd: "stats", data: @stats