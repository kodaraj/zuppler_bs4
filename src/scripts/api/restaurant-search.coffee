$ = require 'jquery'
{ wrapRequest } = require 'utils/request'

SERVICE_URL =  '#{API3_SVC}/v4/restaurants/search.json'

module.exports =
  search: (query) ->
    wrapRequest $.ajax
      url: SERVICE_URL
      type: 'POST'
      data:
        query: JSON.stringify query

  toESQuery: (term) ->
    lowerQueryStr = term.toLowerCase()
    {
      query:
        match_all: {}
      filter:
        bool:
          must: {term: {state: 'published'}}
          should: [
              { wildcard: { name_str: { value: "*#{lowerQueryStr}*" }}}
              { prefix: { permalink: { value: lowerQueryStr, boost: 2 }}}
              { prefix: { name_str: { value: lowerQueryStr, boost: 2 }}}
              { prefix: { name_str: { value: lowerQueryStr + ' ', boost: 4 }}}
            ]
    }
