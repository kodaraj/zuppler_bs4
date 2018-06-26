Bacon = require 'baconjs'
R = require 'ramda'
ChangeTracker = require 'utils/trackSeenOrders'
Dispatcher = require 'utils/dispatcher'
d = new Dispatcher("feedback")

client = require 'api/auth'
reqUtil = require 'utils/request'
resUtil = require 'utils/resources'

feedbackStore = require 'stores/feedback'

loadReviews = ({ type, page, asc, maxRating }) ->
  Bacon
    .once("#{type}Reviews")
    .flatMap (svc) ->
      params =
        # pageSize: 20 # This crashes feedback svc
        pageIndex: page
        asc: asc
        maxRating: maxRating
      Bacon.fromPromise reqUtil.wrapRequest client.api(svc, "get", params )
    .mapError -> { ratings: [] }
    .map R.prop('ratings')

class Feedback
  @MODEL_VERSION: 1
  constructor: (payload) ->
    @type     = 'reviews'
    { @id, @name, @_version } = payload
    @id ||= "inbox"
    @name ||= "Reviews"
    @_version ||= Feedback.MODEL_VERSION

    @reviews = Bacon.update {type: 'open', page: 1, asc: payload.asc || false, maxRating: payload.maxRating || 5},
      [ d.stream('change-type') ], ({asc, maxRating}, type) ->
        { type, page: 1, asc, maxRating }
      [ d.stream('change-page') ], ({ type, asc, maxRating }, page) ->
        { type, page, asc, maxRating }
      [ d.stream('toggle-sort-dir') ], ({type, asc, maxRating, page}, _) ->
        { type, page, maxRating, asc: !asc }
      [ d.stream('max-rating') ], ({type, asc, page}, maxRating) ->
        { type, page, maxRating, asc }
      [ d.stream('reload-reviews') ], (data) ->
        data
      [ Bacon.interval(5*60*1000) ], (data) ->
        data

    @data = @reviews.flatMap(loadReviews).toProperty()
    @asc = @reviews.map R.prop('asc')
    @status = @reviews.map R.prop('type')
    @maxRating = @reviews.map R.prop('maxRating')
    @page = @reviews.map(R.prop('page'))
    @reviewsType = @reviews.map(R.prop('type'))
    @loading = @reviews.awaiting(@data)

    trackingId = (rating) -> "#{rating.id}-#{rating.session.score}"
    changeTracker = @data
      .scan new ChangeTracker, (t, data) -> t.track data.map trackingId
      .skip 2 # Skip first 2 events as they are initial and first read
    @activity = changeTracker.map (t) -> t.lastChange > 0

  toggleSortDir: ->
    d.stream('toggle-sort-dir').push new Date

  setMaxRating: (maxRating) ->
    d.stream('max-rating').push maxRating

  setPage: (page) ->
    d.stream('change-page').push page

  setReviewsType: (type) ->
    d.stream('change-type').push type

  reloadReviews: ->
    d.stream('reload-reviews').push new Date

  toExternalForm: ->
    R.pick ['id', 'type', 'name', 'asc', 'status', 'maxRating', '_version'], @

module.exports = Feedback
