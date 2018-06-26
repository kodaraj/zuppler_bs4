$ = require 'jquery'
{ wrapRequest } = require 'utils/request'
client = require 'api/auth'


module.exports =
  search: (payload) ->
    wrapRequest client.api 'search_users', 'post', payload

  toESQuery: (term) ->
    lowerQueryStr = term.toLowerCase()
    name: term
    email: term
    phone: term
