Bacon = require 'baconjs'
R = require 'ramda'
client = require 'api/auth'
Dispatch = require 'utils/dispatcher'

d = new Dispatcher("seaarch-restaurant")

searchRestaurants = d
  .stream('restaurants')
  .flatMapLatest (term) ->
    Bacon.fromPromise(fetchRestaurants(toESQuery(term)))
  .map (data) -> data.restaurants

module.exports = searchRestaurants
