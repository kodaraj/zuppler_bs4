{ wrapRequest } = require 'utils/request'
client = require 'api/auth'

module.exports =
  search: (query) ->
    wrapRequest client.api "delivery_service", query

  toQuery: (term) ->
    name: term
