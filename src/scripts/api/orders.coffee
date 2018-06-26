R = require 'ramda'
$ = require 'jquery'
usersApi = require 'api/users'
client = require 'api/auth'
Cache = require 'lru-cache'
requestUtils = require 'utils/request'

{ wrapRequest } = requestUtils

window.apiLogging = false

CACHE = new Cache
  max: 50
  maxAge: 1000 * 60 * 60

module.exports =
  search: (appliesTo, sort, dir, page, conditions) ->
    data = R.mergeAll [conditions, appliesTo: appliesTo, sort_by: sort, sort_direction: dir, page: page]
    console.info "[SEARCH ORDERS]", data if window.apiLogging
    wrapRequest client.api "orders", data, "[get orders done]"

  loadFromURL: (url, cache) ->
    if cache and data = CACHE.get(url)
      console.info "[CACHE][GET]", url if window.apiLogging
      res = $.Deferred()
      res.resolve data
      res
    else
      console.info "[GET]", url if window.apiLogging
      res = wrapRequest client.api(url), "[get done]"
      if cache
        res.then (data) ->
          CACHE.set url, data
          data
      res

  executeAction: (url, params) ->
    console.log "[EXECUTE ACTION]", url if window.apiLogging
    wrapRequest client.api(url, 'put', params), "[execute action done]"

  createEvent: (url, params) ->
    console.log "[CREATE EVENT]", url if window.apiLogging
    wrapRequest client.api(url, 'post', params), "[create event done]"
