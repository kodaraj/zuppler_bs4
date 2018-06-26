Bacon = require 'baconjs'
R = require 'ramda'
client = require 'api/auth'
$ = require 'jquery'
api = require 'api/restaurant-search'

terms = new Bacon.Bus

termsStream = terms
  .debounce(200)

searchRestaurants = termsStream
  .map api.toESQuery
  .flatMapLatest (query) ->
    Bacon.fromPromise api.search query
  .map (data) -> data.restaurants

loading = termsStream.awaiting(searchRestaurants)

module.exports =
  search: (term) -> terms.push term
  results: searchRestaurants
  loading: loading
