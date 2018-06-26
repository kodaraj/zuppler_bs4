# Take from milankinen/react-bacon-todomvc
Bacon = require 'baconjs'

class Dispatcher
  constructor: (@storeName = "BUS")->
    @_busCache = {}

  bus: (name) ->
    unless @_busCache[name]
      @_busCache[name] = new Bacon.Bus()
      @_busCache[name].log("[#{@storeName}::#{name}]: ")
    @_busCache[name]

  stream: (name) ->
    @bus(name)

  push: (name, value) ->
    @bus(name).push value

  plug: (name, value) ->
    @bus(name).plug value

module.exports = Dispatcher
