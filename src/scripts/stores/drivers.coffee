$ = require 'jquery'
Bacon = require 'baconjs'
R = require 'ramda'

ordersApi = require 'api/orders'

Dispatcher = require 'utils/dispatcher'
resUtil = require 'utils/resources'

{ wrapRequest, wrapWithRetry } = require 'utils/request'
{ geoDistance, drivingDistance } = require 'utils/geo'

d = new Dispatcher("drivers")

# Load drivers streams
downloadDrivers = (url) ->
  wrapWithRetry(R.partial ordersApi.loadFromURL, [url])
  .map (data) -> data.drivers

driversLoader = d.stream('order')
  .map (order) ->
    resUtil.findResourceLink order, 'drivers', 'get'
  .map (url) -> "#{url}?online=true"
  # .map (url) -> "#{url}"
  .flatMap downloadDrivers

loadingDrivers = d.stream('order')
  .awaiting(driversLoader).toProperty()

distanceTrigger = Bacon.mergeAll(Bacon.once('geodistance'), d.stream('driving')).toProperty()

googleDrivingDistance = (d, lat1, lon1, lat2, lon2, unit) ->
  drivingDistance(lat1, lon1, lat2, lon2, unit)
  .map R.assoc('distance', R.__, d)

driversList = Bacon.combineTemplate
  restaurant: d.stream('restaurant').toProperty()
  distance: distanceTrigger
  drivers: driversLoader
.flatMap ({restaurant, distance, drivers}) ->
  r = restaurant
  if distance == 'geodistance'
    new Bacon.Next R.map (d)->
      R.assoc('distance', geoDistance(parseFloat(r.address.lat), parseFloat(r.address.lng), d.lat, d.lng, 'M'), d)
    , drivers
  else
    Bacon.combineAsArray R.map (d)->
      if d.lat && d.lng
        console.log 'position present'
        googleDrivingDistance(d, parseFloat(r.address.lat), parseFloat(r.address.lng), d.lat, d.lng, 'M')
      else
        Bacon.Next 0
    , drivers

driversList.log()

errors = driversLoader.errors()
  .mapError (error) -> error

clearErrors = driversLoader.map -> null

errorsStream = Bacon
  .mergeAll errors, clearErrors
  .skipDuplicates()

module.exports =
  push: (o)-> d.stream('order').push o
  initRestaurant: (r)-> d.stream('restaurant').push r
  calculateDriving: -> d.stream('driving').push('drivingdistance')
  drivers: driversList
  errors: errorsStream.toProperty()

  loading: loadingDrivers
