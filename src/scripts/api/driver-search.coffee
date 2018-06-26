{ wrapRequest } = require 'utils/request'
client = require 'api/auth'

module.exports =
  search: (query) ->
    wrapRequest client.api "drivers", query

  toQuery: (term) ->
    name: term
