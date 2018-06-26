$ = require 'jquery'
Bacon = require 'baconjs'

window.simulateErrors = false
window.simulateErrorCode = 500

wrapRequest = (promise, log) ->
  res = $.Deferred()
  promise.then (data) ->
    if simulateErrors
      res.reject {success: false, status: {code: simulateErrorCode, message: 'simulated crash boom bang!'}}
    else if data.success
      res.resolve data
    else
      res.reject data
  , (data) ->
    res.reject {success: false, status: {code: 503, message: 'connection timeout'}}
  res

wrapRequestJSON = (promise, log) ->
  res = $.Deferred()
  promise.then (data) -> res.resolve data
  , (data) -> res.reject data
  res

wrapWithRetry = (apiCall, delay = 300) ->
  Bacon
    .retry
      source: ->
        Bacon.fromPromise apiCall()
      retries: 5
      isRetryable: (data) -> data.status.code != 500
      delay: (ctx) ->
        delay * ctx.retriesDone

module.exports =
  wrapRequest: wrapRequest
  wrapRequestJSON: wrapRequestJSON
  wrapWithRetry: wrapWithRetry
