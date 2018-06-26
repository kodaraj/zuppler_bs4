Bacon = require 'baconjs'

# WS RELATED
ws = null
wsInputStream = new Bacon.Bus
wsOutputStream = new Bacon.Bus
wsConnected = new Bacon.Bus

wsConnect = ->
  s = new WebSocket(PRESENCE_SVC)
  s.onopen = -> wsConnected.push true
  s.onmessage = wsOnMessage
  s.onclose = wsOnClose
  s

wsOnMessage = (data) ->
  wsInputStream.push JSON.parse event.data

wsOnClose = ->
  wsConnected.push false
  ws = wsConnect()

notStream = (b) -> !b

wsOutputStream
  .map JSON.stringify
  .holdWhen wsConnected.map notStream
  .onValue (s) -> ws.send s

wsConnected.push false
wsConnected.log("[ws] CONNECTED")

ws = wsConnect()

module.exports =
  output: wsOutputStream
  input: wsInputStream
  connected: wsConnected
