R = require 'ramda'
moment = require 'moment'

_1DAY = 24*60
###*
 * Givin an day*[[open,close]*] structure returns different informations based
 * on given datetime or current
###
minuteToDate = (minute, d) ->
  adjDay = if minute >= _1DAY then 1 else 0
  minute = minute - _1DAY if adjDay
  hour = Math.floor minute / 60
  min = minute % 60
  d.hours(hour).minutes(min).seconds(0).milliseconds(0).add(adjDay, 'days')

intervalToString = (o) ->
  "[#{o.start.format('ddd hh:mm a')} - #{o.end.format('hh:mm a ZZ')}]"

dateIntervals = (s, start = moment()) ->
  mapIndexed = R.addIndex(R.map)
  mapped = R.flatten mapIndexed (intervals, day) ->
    mapped = R.map (interval) ->
      start: minuteToDate(interval[0], start.clone().day(day))
      end: minuteToDate(interval[1], start.clone().day(day))
    , intervals
  , s

  filtered = R.filter (o) ->
    !o.start.isSame(o.end)
  , mapped

  R.reduce (acc, o) ->
    last = acc.pop()
    if last and last.end.isSame(o.start)
      acc.push start: last.start, end: o.end
    else
      acc.push last if last
      acc.push o
    acc
  , [], filtered

findInterval = (intervals, d = moment()) ->
  interval = R.find (i) ->
    d.isBetween(i.start, i.end)
  , intervals

closingTime = (s, d = moment()) ->
  interval = findInterval s, d
  if interval then interval.end

nextWeek = (intervals) ->
  R.map (o) ->
    start: o.start.clone().add(1, 'week')
    end: o.end.clone().add(1, 'week')
  , intervals

openingTime = (intervals, d = moment()) ->
  interval = R.find (i) ->
    i.start.isAfter(d)
  , intervals
  if interval
    interval.start
  else
    openingTime nextWeek intervals, d

status = (s, d = moment()) ->
  !!findInterval s, d

class HoursOfOperation
  constructor: (hopInfo, @utcOffset) ->
    @intervals = R.map (o) ->
      start: o.start
      end: o.end
    , dateIntervals hopInfo, moment().utcOffset(@utcOffset)

  status: (d = moment()) ->
    status @intervals, d
  openingTime: (d = moment()) ->
    openingTime @intervals, d
  closingTime: (d = moment()) ->
    closingTime @intervals, d
  openingHours: (d = moment()) ->
    findInterval @intervals, d

module.exports =
  status: status
  closingTime: closingTime
  openingTime: openingTime
  intervalsFromMinutes: dateIntervals
  HoursOfOperation: HoursOfOperation
