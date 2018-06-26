R = require 'ramda'

POINT_TYPES = ['bus_station', 'establishment', 'transit_station', 'premise', 'subpremise', 'airport', 'park', 'point_of_interest', 'intersection']

# locationPrecision :: [String] -> Precision
locationPrecision = (locationTypes) ->
  if R.intersection(POINT_TYPES, locationTypes).length > 0
    5
  else if R.intersection(['street_address'], locationTypes).length > 0
    10
  else if R.intersection(['route'], locationTypes).length > 0
    15
  else if R.intersection(['locality'], locationTypes).length > 0
    30
  else if R.intersection(['administrative_area_level_1'], locationTypes).length > 0
    40
  else
    50

# reqPrecisionToNumber :: String -> Precision
reqPrecision = (precision) ->
  switch precision
    when 'city' then 30
    when 'street' then 10
    else 50

# address validator
# address :: Maybe location -> Map -> String -> Map -> Maybe error
address = (value, options, key, attributes) ->
  locationTypes = R.compose(R.defaultTo([]), R.path(['gmaps', 'types']))
  p1 = value?.precision || locationPrecision locationTypes value
  p2 = reqPrecision(options.precision)
  "needs to be given at #{options.precision} level" if p1 > p2


module.exports = (validateLib) ->
  validateLib.validators.address = address
  validateLib
