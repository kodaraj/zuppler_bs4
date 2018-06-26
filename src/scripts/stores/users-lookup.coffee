Bacon = require 'baconjs'
R = require 'ramda'
api = require 'api/users-search'

terms = new Bacon.Bus

search = terms
  .debounce(200)
  .map api.toESQuery
  .flatMapLatest (query) ->
    Bacon.fromPromise api.search query
  .map (data) -> data.users

loading = terms.awaiting search

module.exports =
  search: (term) -> terms.push term
  results: search
  loading: loading
