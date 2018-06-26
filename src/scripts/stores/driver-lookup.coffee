Bacon = require 'baconjs'
api = require 'api/driver-search'

terms = new Bacon.Bus

termsStream = terms
  .debounce(200)

searchDrivers = termsStream
  .map api.toQuery
  .flatMapLatest (query) ->
    Bacon.fromPromise api.search query
  .map (data) -> data.drivers

loading = termsStream.awaiting(searchDrivers)

module.exports =
  search: (term) -> terms.push term
  results: searchDrivers
  loading: loading
