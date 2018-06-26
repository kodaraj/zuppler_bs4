Dispatcher = require 'utils/dispatcher'

describe 'push', ->
  d = null

  beforeEach (done) ->
    d = new Dispatcher
    done()

  it "should have 1 value", (done) ->
    lv = null
    d.stream('test').onValue (v) ->
      lv = v
    d.push 'test', 1
    setTimeout ->
      expect(lv).toBe 1
      done()
    , 0
