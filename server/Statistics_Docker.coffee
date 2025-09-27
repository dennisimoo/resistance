# Statistics class for Docker deployment (without webworker-threads dependency)

class StatisticsDockerFix
    constructor: (@db) ->
        @stats = {}
        @tables = {}
        # setInterval (=> @refresh()), 4 * 60 * 60 * 1000
        # Disabled StatisticsWorkers for Docker deployment
        @statsWorkers = null
        @statsWorker = null

        # Initialize empty stats
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

    getActivePlayers: (tables) ->
        return []

    getLeaderboard: (tables) ->
        return []

    getRecentGames: (tables) ->
        return []

    getWinRates: (tables) ->
        return {}

    getActivity: (tables) ->
        return {}

    getRatings: (tables) ->
        return []

    getRatings2: (tables) ->
        return []

    respond: (player) ->
        return player.send cmd: "stats", data: @stats