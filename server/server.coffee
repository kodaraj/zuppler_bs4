express = require 'express'
compress = require 'compression'
http = require 'http'
path = require 'path'
logger = require 'morgan'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
debug = require('debug')('react-express-template')
fs = require 'fs'

dist = path.join(__dirname, '../dist')
app = express()

initServer = ->
  app.use logger('dev')
  app.use bodyParser.json()
  app.use bodyParser.urlencoded(extended: true)
  app.use cookieParser()
  app.use compress()

  app.use express.static(dist)

  app.set 'port', process.env.PORT or 8080

  app.get '/', (req, res)->
    res.render('index.html')

  app.get '/auth', (req, res)->
    res.render('auth.html')

  app.get '/ping', (req, res)->
    res.send('PONG')

  ## error handlers
  app.use(require('express-domain-middleware'))

  # development error handler
  # will print stacktrace
  if app.get("env") is "development"
    app.use (err, req, res, next) ->
      console.log err.stack
      res.status err.status or 500
      res.send(message: err.message, status: err.status, stack: err.stack)
  else
    # production error handler
    # no stacktraces leaked to user
    app.use (err, req, res, next) ->
      console.error(err.stack)
      res.status err.status or 500
      res.send(message: err.message)

  server = http.createServer(app)
  server.listen app.get('port'), ->
    console.info 'Express server listening on port ' + server.address().port

# SERVER initialization
domain = require 'domain'
d = domain.create()
d.on 'error', (err)->
  console.error(err)

d.run ->
  initServer()
