class Statistics
    constructor: (database) ->
        @db = database
        @stats =
            activeplayers: []
            leaderboard: []
            recentgames: []
            winrates: {}
            activity: {}
            ratings: []
            ratings2: []

    refresh: () ->
        console.log "Statistics refresh disabled in Docker deployment"

    respond: (player) ->
        player.send cmd: "stats", data: @stats
