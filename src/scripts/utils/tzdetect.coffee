R = require 'ramda'
moment = require 'moment-timezone'
data = require 'moment-timezone/data/meta/latest.json'
knownCountries = ['US', 'CA', 'GB', 'IE', 'NL', 'SG', "IN", "RO"]
knownTZs = R.flatten R.map R.prop('zones'), R.values R.pick knownCountries, data.countries
knownTZGroups = R.map R.pick(['name', 'zones']), R.values R.pick knownCountries, data.countries
module.exports =
  names: knownTZs
  groups: knownTZGroups
  guess: moment.tz.guess
  matches: (base) ->
    results = []
    now = Date.now()
    makekey = (id) ->
      matches = [0, 4, 8, -5*12, 4-5*12, 8-5*12, 4-2*12, 8-2*12].map (months) ->
        m = moment now + months*30*24*60*60*1000
        m.tz(id) if (id)
        m.format "DDHHmm"
      matches.join(' ')
    lockey = makekey(base)

    moment.tz.names().forEach (id) ->
      if makekey(id) is lockey
        results.push id
    results
