R = require 'ramda'
Immutable = require 'immutable'

class Tracker
  constructor: (initial = []) ->
    @data = Immutable.Set(initial)
    @lastChange = 0

  track: (col, replace = true) ->
    newData = Immutable.Set(col)
    diffs = newData.subtract(@data)
    @lastChange = diffs.count()
    if replace
      @data = newData
    else
      @data = @data.union(newData)
    @

  size: ->
    @data.count()

module.exports = Tracker
