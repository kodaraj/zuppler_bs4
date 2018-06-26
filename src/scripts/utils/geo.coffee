$ = require 'jquery'
Bacon = require 'baconjs'
# distance = require('google-distance')
# distance.apiKey = GOOGLE_API_KEY
distance = null

# https://www.geodatasource.com/developers/javascript
geoDistance = (lat1, lon1, lat2, lon2, unit) ->
  return '' unless lat1 && lon1 && lat2 && lon2
  radlat1 = Math.PI * lat1/180
  radlat2 = Math.PI * lat2/180
  radlon1 = Math.PI * lon1/180
  radlon2 = Math.PI * lon2/180
  theta = lon1-lon2
  radtheta = Math.PI * theta/180
  dist = Math.sin(radlat1) * Math.sin(radlat2) + Math.cos(radlat1) * Math.cos(radlat2) * Math.cos(radtheta)
  dist = Math.acos(dist)
  dist = dist * 180/Math.PI
  dist = dist * 60 * 1.1515
  if unit=="K" then dist = dist * 1.609344
  if unit=="M" then dist = dist * 0.8684
  dist.toFixed(2)

# baseUrl = "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&key=#{GOOGLE_API_KEY}"
# service = new google.maps.DistanceMatrixService()

drivingDistance = (lat1, lon1, lat2, lon2, unit) ->
  # url = "#{baseUrl}&origins=#{lat1},#{lon1}&destinations=#{lat2},#{lon2}"
  origin = "#{lat1},#{lon1}"
  destination = "#{lat2},#{lon2}"

  Bacon.fromCallback (callback)->
    distance.get(
      {
        origin: origin
        destination: destination
        units: 'imperial'
      },
      (err, data) ->
        retun new Bacon.Error(err) if (err)
        callback(data)
    )
  .map (result)->
    console.log result
    0

module.exports =
  geoDistance: geoDistance
  drivingDistance: drivingDistance
