hello = require 'hellojs'
R = require 'ramda'

isMultiLevelJSON = (data) ->
  R.any R.or(R.is(Object), R.isArrayLike), R.values data

toJSON = (p) ->
  if R.is(Object, p.data) and isMultiLevelJSON(p.data)
    p.data = JSON.stringify(p.data)
    p.headers['content-type'] = 'application/json'

usersService =
  users:
    id: APP_CLIENT_ID
    name: 'users'
    oauth:
      version : 2
      auth: "#{USERS_SERVER}/oauth/authorize"
      grant: "#{USERS_SERVER}/oauth/token"
    refresh: true
    scope:
      basic: 'public'
    scope_delim: ' '
    base: USERS_SERVER
    form: false
    jsonp: false
    get:
      me: "/users/current"
      settings: "/v1/settings.json"
      orders: "#{ORDERS_SVC}/v4/orders.json"
      restaurants: "#{CP_SVC}/restaurants.json"
      takeouts: "#{REPORTS_SVC}/takeouts.json"
      takeout_templates: "#{REPORTS_SVC}/takeouts/templates.json"
      feedbackSession: "#{FEEDBACK_SVC}/sessions/index.json"
      openReviews: "#{FEEDBACK_SVC}/feedbacks/open.json"
      seenReviews: "#{FEEDBACK_SVC}/feedbacks/seen.json"
      drivers: "#{RDSAAS_SVC}/v1/api/drivers.json"
      delivery_service: "#{RDSAAS_SVC}/v1/api/delivery_services.json"
      searchRestaurants: "#{API3_SVC}/v4/restaurants/search.json"
    post:
      takeout: "#{REPORTS_SVC}/takeouts.json"
      search_users: '/v1/users/search.json'
      searchRestaurants: "#{API3_SVC}/v4/restaurants/search.json"
    put:
      settings: "/v1/settings.json"
    xhr: (p, qs) ->
      makeBaseAuth = (user, password) ->
        tok = user + ':' + password
        hash = btoa tok
        "Basic #{hash}"
      p.headers['OAUTH_VERSION'] = 'v2' # for CP
      if p.method is "post" or p.method is 'put'
        toJSON(p)
      if p.path == "orders"
        p.headers['Authorization'] = makeBaseAuth 'zuppler', 'api'
      true

helloOptions =
  redirect_uri: AUTH_CALLBACK_URL
  display: 'popup'

hello.init usersService, helloOptions

module.exports = hello('users')
