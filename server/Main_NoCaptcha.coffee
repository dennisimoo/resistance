express = require('express')
createSessionKey = require('crypto').randomBytes
toQueryString = require('querystring').stringify
http = require('http')
https = require('https')
fs = require('fs')
cookie = require('cookie')

getPlayer = (req, res) ->
    sessionKey = req.cookies.sessionKey
    if not sessionKey or not g.playersBySessionKey[sessionKey]?
        res.send 401 # Unauthorized
        return null
    return g.playersBySessionKey[sessionKey]

gcPlayers = ->
    now = Date.now()
    playersToGc = (player for sessionKey, player of g.playersBySessionKey when now - player.lastConnectTime > 10 * 60 * 1000)

    for player in playersToGc
        player.setRoom(g.lobby) if player.room isnt g.lobby
        g.lobby.onPlayerLeave(player)
        g.lobby.onPlayerLogout(player)
        delete g.playersBySessionKey[player.sessionKey]
        delete g.playersById[player.id]

    if playersToGc.length > 0
        for id, player of g.playersById
            player.flush()

app = express()

#app.get '*', (req, res) -> res.send('Down for maintenence. ETA: 9pm Pacific (0400 GMT)');
#app.use express.logger()
app.use express.json()
app.use express.cookieParser()

app.get '/server/stats/:statType', (req, res) ->
    res.header('Cache-Control', 'max-age=900')
    res.send(200, g.stats.get(req.params.statType))

app.get '/server/health', (req, res) ->
    # Simple health check that tests database connectivity
    g.db.withClient res.send(500), (client, errH) ->
        client.query "SELECT COUNT(*) as count FROM users", [], (err, result) ->
            if err
                console.log "Health check error:", err
                return errH(err)
            console.log "Health check: found", result.rows[0].count, "users"
            res.send { status: 'ok', users: result.rows[0].count }

app.get '/server/role', (req, res) ->
    player = getPlayer(req, res)
    return res.send(400) if not player?
    role = if g.options.mods.indexOf(player.name.toLowerCase()) >= 0 then 'mod' else 'user'
    return res.send { role: role, id: player.id }

app.get '/server/play', (req, res) ->
    player = getPlayer(req, res)
    return if not player?

    player.lastConnectTime = Date.now()

    res.header('Cache-Control', 'no-cache')

    if player.messageQueue.length is 0
        player.messageQueue.push({ cmd: 'ack' }) if not player.response?
        player.response = res
        req.on 'close', -> delete player.response
    else
        res.send(player.messageQueue)
        player.messageQueue = []

app.post '/server/play', (req, res) ->
    player = getPlayer(req, res)
    return if not player?
    player.onRequest(req.body)
    res.send(200)

app.put '/server/hide', (req, res) ->
    player = getPlayer(req, res)
    return res.send(401) if not player?

    # Simple implementation - just acknowledge the request
    # The original uses g.db.updateUserStatsHidden but we'll skip database calls
    console.log "Player #{player.name} updated stats hidden to:", req.body.statsHidden
    res.send(200)

app.get '/server/notifications', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    # Return empty notifications for now - original uses g.discussions.getNotifications
    res.send([])

app.put '/server/notifications', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    # Simple acknowledgment - original uses g.discussions.updateNotification
    res.send({ success: true })

app.delete '/server/notifications', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    # Simple acknowledgment - original uses g.discussions.updateNotificationHidden
    res.send({ success: true })

app.get '/server/discussions', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    # Return empty discussions for now
    res.send([])

app.get '/server/discussions/:id', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    # Return empty discussion for now
    res.send({ posts: [] })

app.get '/server/mutes', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    # Return empty mutes list
    res.send([])

app.get '/server/views', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    # Return empty views
    res.send([])

app.post '/server/login', (req, res) ->
    sessionKey = req.cookies.sessionKey

    if sessionKey and g.playersBySessionKey[sessionKey]?
        return res.send(200)

    return res.send(400, 'Invalid username') if !req.body.username? || !req.body.password?

    console.log "Login attempt for:", req.body.username

    # Direct login using psql approach like registration
    { exec } = require('child_process')
    bcrypt = require('bcryptjs')

    # Escape single quotes in username
    escapedName = req.body.username.replace(/'/g, "''")

    # Get user info with password hash (decode binary passwd back to string)
    sql = "SELECT id, encode(passwd::bytea, 'escape') as passwd, res_img, spy_img, avatar_enabled, role_tokens FROM users WHERE LOWER(name) = LOWER('#{escapedName}') AND is_valid = true;"
    psqlCmd = "PGPASSWORD=resistance_pass psql -h postgres -U resistance_user -d resistance -t -c \"#{sql}\""

    exec psqlCmd, (error, stdout, stderr) ->
        if error
            console.log "Login database error:", error.message
            return res.send(400, 'Invalid username or password')

        stdout = stdout.trim()
        if not stdout
            console.log "User not found:", req.body.username
            return res.send(400, 'Invalid username or password')

        # Parse the result (format: id | passwd | res_img | spy_img | avatar_enabled | role_tokens)
        parts = stdout.split('|').map((p) -> p.trim())
        if parts.length < 6
            console.log "Invalid user data format"
            return res.send(400, 'Invalid username or password')

        playerId = parseInt(parts[0])
        storedHash = parts[1]
        res_img = parts[2]
        spy_img = parts[3]
        avatar_enabled = parts[4] == 't'
        role_tokens = parseInt(parts[5]) || 0

        # Verify password
        if not bcrypt.compareSync(req.body.password, storedHash)
            console.log "Invalid password for:", req.body.username
            return res.send(400, 'Invalid username or password')

        console.log "Login successful for:", req.body.username, "ID:", playerId

        # Handle existing player session
        if g.playersById[playerId]?
            g.playersById[playerId].setRoom(g.lobby) if g.playersById[playerId].room isnt g.lobby
            g.lobby.onPlayerLeave(g.playersById[playerId])
            g.lobby.onPlayerLogout(g.playersById[playerId])
            delete g.playersBySessionKey[g.playersById[playerId].sessionKey]

        sessionKey = createSessionKey(16).toString('hex')

        # Create player object (simplified - skip ban check for now)
        g.playersById[playerId] = new Player(req.body.username, playerId, res_img, spy_img, avatar_enabled, role_tokens, sessionKey, g.lobby)
        g.lobby.onPlayerLogin(g.playersById[playerId])
        g.playersBySessionKey[sessionKey] = g.playersById[playerId]
        res.cookie 'sessionKey', sessionKey
        res.send(200)

app.post '/server/register', (req, res) ->
    isEmpty = (x) -> not x? or x is ''

    return res.send(400, 'Invalid username') if isEmpty req.body.username
    return res.send(400, 'Invalid character in username') if !req.body.username.split('').every((i) ->  32 <= i.charCodeAt(0) < 127)
    return res.send(400, 'Invalid username') if req.body.username[0] is ' ' or req.body.username[req.body.username.length - 1] is ' '
    return res.send(400, 'Invalid username') if req.body.username.match(/\ \ /)
    return res.send(400, 'Invalid password') if isEmpty(req.body.password1) or req.body.password1 isnt req.body.password2
    return res.send(400, 'Invalid email') if isEmpty(req.body.email) or req.body.email.length < 3 or req.body.email.indexOf('@') is -1

    console.log "Simple registration for:", req.body.username

    # Simple approach using child_process to execute psql directly
    { exec } = require('child_process')
    bcrypt = require('bcryptjs')

    cryptpass = bcrypt.hashSync(req.body.password1, 8)

    # Use base64 encoding to safely pass the bcrypt hash
    cryptpassBase64 = Buffer.from(cryptpass).toString('base64')
    escapedName = req.body.username.replace(/'/g, "''")
    escapedEmail = req.body.email.replace(/'/g, "''")

    # Use decode to convert base64 back to original hash
    sql = "INSERT INTO users(name, passwd, is_valid, email) VALUES ('#{escapedName}', decode('#{cryptpassBase64}', 'base64'), true, '#{escapedEmail}') RETURNING id;"

    psqlCmd = "PGPASSWORD=resistance_pass psql -h postgres -U resistance_user -d resistance -c \"#{sql}\""

    exec psqlCmd, (error, stdout, stderr) ->
        if error
            console.log "Registration error:", error.message
            return res.send(400, 'Username already exists')

        console.log "Registration successful for:", req.body.username
        res.send(200)

app.post '/server/ban', (req, res) ->
    player = getPlayer(req, res)
    return if not player?
    return if g.options.mods.indexOf(player.name.toLowerCase()) < 0
    g.bans.addBan req.body.playerId, req.body.duration, req.body.banType, player.id, req.body.reason || '', (err) ->
        return console.log err if err?
        # log player out
        player = g.playersById[req.body.playerId]
        player.setRoom(g.lobby) if player.room isnt g.lobby
        g.lobby.onPlayerLeave(player)
        g.lobby.onPlayerLogout(player)
        delete g.playersBySessionKey[player.sessionKey]
        delete g.playersById[player.id]
        for id, player of g.playersById
            player.flush()
        res.send(200)

app.post '/server/mod', (req, res) ->
    player = getPlayer(req, res)
    return if not player?
    return if g.options.mods.indexOf(player.name.toLowerCase()) < 0
    switch req.body.cmd
        when 'ban'
            g.bans.addBan req.body.args[0], req.body.args[1], req.body.args[2], player.id, req.body.args[3] || '', (err) ->
                return console.log err if err?
                # log player out
                player = g.playersById[req.body.args[0]]
                player.setRoom(g.lobby) if player.room isnt g.lobby
                g.lobby.onPlayerLeave(player)
                g.lobby.onPlayerLogout(player)
                delete g.playersBySessionKey[player.sessionKey]
                delete g.playersById[player.id]
                for id, player of g.playersById
                    player.flush()
        when 'unban'
            g.bans.deleteBan req.body.args[0], (err) ->
                return console.log err if err?
        when 'msg'
            player.messageQueue.push({ cmd: 'serverbcast', data: req.body.args[0] })
            player.flush()
            for id, otherPlayer of g.playersById
                continue if otherPlayer is player
                otherPlayer.messageQueue.push({ cmd: 'serverbcast', data: req.body.args[0] })
                otherPlayer.flush()
    res.send(200)

app.post '/server/action', (req, res) ->
    player = getPlayer(req, res)
    return if not player?

    player.lastConnectTime = Date.now()

    player.room.onMessage(player, req.body)
    res.send(200)

app.post '/server/upload', (req, res) ->
    player = getPlayer(req, res)
    return if not player?
    return res.send(400, 'Invalid data') if !req.body.data? or req.body.data.length > 8192
    switch req.body.type
        when 'resimg'
            g.db.setResImg player.id, req.body.data, (err) ->
                return res.send(400) if err?
                player.resImg = req.body.data
                res.send(200)
        when 'spyimg'
            g.db.setSpyImg player.id, req.body.data, (err) ->
                return res.send(400) if err?
                player.spyImg = req.body.data
                res.send(200)
        else
            res.send(400)

app.post '/server/account', (req, res) ->
    player = getPlayer(req, res)
    return if not player?
    switch req.body.type
        when 'avatar'
            g.db.setAvatarEnabled player.id, req.body.enabled, (err) ->
                return res.send(400) if err?
                player.avatarEnabled = req.body.enabled
                res.send(200)
        when 'roletokens'
            g.db.setRoleTokens player.id, req.body.enabled, (err) ->
                return res.send(400) if err?
                player.roleTokens = req.body.enabled
                res.send(200)
        else
            res.send(400)

app.use express.static('client')

# Load options first
g.options = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'))
g.playersBySessionKey = {}
g.playersById = {}
g.mutedPlayers = []
g.anonPlayerNames = null
g.uidNext = 0

g.db = new Database()
g.db.initialize (err) ->
    return console.log err if err
    g.lobby = new Lobby()
    g.stats = new Statistics(g.db)
    g.bans = new Bans(g.db)
    g.rating = new Rating(g.db)
    g.tokens = new Tokens(g.db)
    g.discussions = new Discussions(g.db)
    g.commands = new Commands(g.db)

    setInterval gcPlayers, 60 * 1000

    app.listen g.options.port
    console.log 'Server started.'