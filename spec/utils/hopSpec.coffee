hop = require 'utils/hop'
moment = require 'moment'

hour = (h, d = moment()) ->
  d.hours(h).minutes(0).seconds(0).milliseconds(0)
day = (dow, d = moment()) ->
  d.day(dow)
dts = (m) -> m.format('ddd hh:mm a ZZ')

describe 'Hours of operations', ->
  workDay = [[6, 10], [11, 16], [16, 22]].map (pair) -> [pair[0] * 60, pair[1] * 60]
  weekendDay = [[0, 0], [11, 16], [18, 25]].map (pair) -> [pair[0] * 60, pair[1] * 60]  
  hopData = hop.intervalsFromMinutes [weekendDay, workDay, workDay, workDay, workDay, workDay, weekendDay]
  
  it '#status', ->
    expect(hop.status(hopData, day(1, hour(9)))).toBe true
    expect(hop.status(hopData, day(1, hour(4)))).toBe false
    expect(hop.status(hopData, day(0, hour(9)))).toBe false
    expect(hop.status(hopData, day(0, hour(4)))).toBe false
    expect(hop.status(hopData, day(0, hour(17)))).toBe false

  it '#closingTime', ->
    expect(hop.closingTime(hopData, day(1, hour(9)))).toEqual day(1, hour(10))
    expect(hop.closingTime(hopData, day(0, hour(9)))).toBeUndefined()

  it '#openingTime', ->
    d = day(1, hour(2))
    d1 = day(1, hour(6))
    r = hop.openingTime(hopData, d)
    expect(r.format('llll')).toEqual d1.format('llll')
    d = day(1, hour(23))
    d1 = day(2, hour(6))
    expect((hop.openingTime(hopData, d))).toEqual d1    
    d = day(0, hour(17))
    d1 = day(0, hour(18))
    expect((hop.openingTime(hopData, d))).toEqual d1
    
    d = day(6, hour(23))
    d1 = day(7, hour(11))    
    r = hop.openingTime(hopData, d)

describe 'HoursOfOperations', ->
  workDay = [[6, 10], [11, 16], [16, 22]].map (pair) -> [pair[0] * 60, pair[1] * 60]
  weekendDay = [[0, 0], [11, 16], [18, 25]].map (pair) -> [pair[0] * 60, pair[1] * 60]  
  hopData = [weekendDay, workDay, workDay, workDay, workDay, workDay, weekendDay]
  it "#status", ->
    hopInfo = new hop.HoursOfOperation hopData, -5*60  
    localTime = day(2, hour(9))
    expect(hopInfo.status(localTime)).toBeFalsy()