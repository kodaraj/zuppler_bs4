utils = require 'utils/time'

describe 'order utils', ->
  it '#timeDiff', ->
    _1MIN = 60
    _1HOUR = 60*_1MIN
    _1DAY = 24*_1HOUR
    
    expect(utils.humanSeconds(3*_1DAY + 8*_1HOUR + 20*_1MIN + 30)).toEqual "3d 8h 20m 30s"
    expect(utils.humanSeconds(8*_1HOUR + 20*_1MIN + 30)).toEqual "8h 20m 30s"
    expect(utils.humanSeconds(3*_1DAY + 0*_1HOUR + 20*_1MIN + 30)).toEqual "3d 20m 30s"
    expect(utils.humanSeconds(28*_1MIN + 30)).toEqual "28m 30s"
    expect(utils.humanSeconds(35)).toEqual "35s"