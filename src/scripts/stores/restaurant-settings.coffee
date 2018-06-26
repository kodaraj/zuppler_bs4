Bacon = require 'baconjs'
R = require 'ramda'

zuppler = require 'api/auth'
reqUtil = require 'utils/request'
resUtil = require 'utils/resources'

userStore = require 'stores/user'

Dispatcher = require 'zuppler-js/lib/utils/dispatcher'

d = new Dispatcher('RestaurantConfig')

cpURL = (restaurantPermalink) ->
  "#{CP_SVC}/restaurants/#{restaurantPermalink}.json"

loadRestaurantJSON = (url) ->
  Bacon.fromPromise zuppler.api(url)

searchQuery = (ids) ->
  data =
    query:
      query:
        terms:
          "_id": ids

pauseOrdering = d.stream('pause-ordering')
  .flatMap ({restaurant, duration}) ->
    url = resUtil.findResourceLink(restaurant, 'pause_ordering', 'put')
    Bacon.fromPromise zuppler.api(url, 'post', _method: 'PUT', hours: duration, pause_online_ordering: true)

resumeOrdering = d.stream('resume-ordering')
  .flatMap (restaurant) ->
    url = resUtil.findResourceLink(restaurant, 'pause_ordering', 'put')
    Bacon.fromPromise zuppler.api(url, 'post', _method: 'PUT', hours: 0, pause_online_ordering: false)

controlPanelUrls = ->
  userStore.loggedIn
    .filter R.equals(true)
    .map -> userStore.acls()
    .map R.prop('restaurant')
    .filter R.pipe(R.length, R.lt(0))
    .flatMap (ids) ->
      Bacon.fromPromise reqUtil.wrapRequest zuppler.api('searchRestaurants', 'post', searchQuery(ids))
    .map R.prop('restaurants')
    .map R.map R.prop('permalink')
    .map R.map cpURL

loadSettings = ->
  urls = controlPanelUrls()
  cpURLS = Bacon.mergeAll urls, urls.sampledBy(Bacon.mergeAll(resumeOrdering, pauseOrdering))
  cpURLS.flatMap (urls) ->
    Bacon.zipAsArray R.map loadRestaurantJSON, urls

loading = Bacon.mergeAll d.stream('pause-ordering').awaiting(pauseOrdering), d.stream('resume-ordering').awaiting(resumeOrdering)

module.exports =
  loadSettings: loadSettings
  loading: loading

  pauseOrdering: (restaurant, duration) ->
    d.stream('pause-ordering').push({restaurant, duration})
    pauseOrdering

  resumeOrdering: (restaurant) ->
    d.stream('resume-ordering').push(restaurant)
    resumeOrdering