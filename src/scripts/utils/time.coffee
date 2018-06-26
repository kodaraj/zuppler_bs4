R = require 'ramda'
moment = require 'moment'

_1min = 1000 * 60
urgent = 30 * _1min
soon = 60 * _1min
later = 4 * 60 * _1min
today = 8 * 60 * _1min

addIndex = (val, index) ->
  [val, index]

humanSeconds = (seconds) ->
  _1MINUTE = 60
  _1HOUR = 60*_1MINUTE
  _1DAY = 24*_1HOUR

  timeParts = R.reverse [
    seconds % 60
    if seconds > _1MINUTE then Math.floor((seconds % _1HOUR) / _1MINUTE) else 0
    if seconds > _1HOUR then Math.floor((seconds % _1DAY) / _1HOUR) else 0
    if seconds > _1DAY then Math.floor(seconds / _1DAY) else 0
  ]

  human = R.reduce (sum, [elem, index]) ->
    unit = "dhms".charAt(index)
    if elem > 0 then "#{sum} #{elem}#{unit}" else sum
  , "", R.addIndex(R.map)(addIndex, timeParts)
  human.trim()

timeDiff = (start, time) ->
  seconds = Math.floor(start.diff(time) / -1000)
  humanSeconds(seconds)

timeSlice = (date) ->
  now = new Date

  distance = date.diff(now)

  if distance < 0
    'passed'
  else if distance < urgent
    'urgent'
  else if distance < soon
    'soon'
  else if distance < later
    'later'
  else if distance < today
    'today'
  else
    'future'

module.exports =
  humanSeconds: humanSeconds
  timeDiff: timeDiff
  timeSlice: timeSlice
