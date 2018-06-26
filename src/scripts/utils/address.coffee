R = require 'ramda'

googlePlaceToZupplerAddress = (address) ->
  precision = placeToZupplerPrecision(address.gmaps.types)

  complete_address: address.label
  nickname:         address.label
  lat:              address.location.lat
  lng:              address.location.lng
  precision:        precision
  street: placeComp(address.gmaps.address_components, ['street_number', 'route'])
  city:   placeComp(address.gmaps.address_components, 'locality')
  state:  placeComp(address.gmaps.address_components, 'administrative_area_level_1', true)
  zip:    placeComp(address.gmaps.address_components, 'postal_code')

min = (a, b) -> if a <= b then a else b

placeToZupplerPrecision = (types) ->
  R.reduce(min, 100, R.map(placeTypeToNumber, types))

placeTypeToNumber = (type) ->
  switch type
    when 'bus_station', 'establishment', 'transit_station', 'premise', 'subpremise', 'airport', 'park', 'point_of_interest', 'intersection' then 5
    when 'street_address' then 10
    when 'route' then 15
    when 'locality' then 30
    when 'administrative_area_level_1' then 40
    else 50

placeComp = (comps, types, short = false) ->
  prop = if short then 'short_name' else 'long_name'
  byType = R.pipe(R.prop('types'), R.intersection(types), R.length, R.lt(0))
  R.join(" ", R.map(R.prop(prop), R.filter(byType, comps)))

zupplerAddressToGeoSuggestFixture = (address) ->
  if address and address.complete_address and address.lat and address.lng
    label: address.complete_address
    location: R.pick(['lat', 'lng'], address)

module.exports =
  googlePlaceToZupplerAddress: googlePlaceToZupplerAddress
  zupplerAddressToGeoSuggestFixture: zupplerAddressToGeoSuggestFixture
