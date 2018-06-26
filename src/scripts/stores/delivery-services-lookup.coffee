Bacon = require 'baconjs'
api = require 'api/delivery-services-search'

terms = new Bacon.Bus

termsStream = terms
  .debounce(200)

searchDeliveryState = termsStream
  .map api.toQuery
  .flatMapLatest (query) ->
    Bacon.fromPromise api.search query
  .map (data) -> data.delivery_services

loading = termsStream.awaiting(searchDeliveryState)

module.exports =
  search: (term) -> terms.push term
  results: searchDeliveryState
  loading: loading
