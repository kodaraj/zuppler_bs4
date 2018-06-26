R = require 'ramda'
Bacon = require 'baconjs'
client = require 'api/auth'
reqUtil = require 'utils/request'
resUtil = require 'utils/resources'
Dispatcher = require 'utils/dispatcher'
userStore = require 'stores/user'
Feedback = require 'models/feedback'

moment = require 'moment'

d = new Dispatcher("feedback")

orderStore = require './order'

feedbackSessionStream = orderStore.current
  .filter (o) -> !!o
  .map (o) -> R.assoc('name', o.id, {})
  .flatMap (params) ->
    Bacon.fromPromise reqUtil.wrapRequest client.api("feedbackSession", 'get', params)
  .flatMap (data) ->
    if data.sessions.length
      new Bacon.Next(data.sessions[0])
    else
      new Bacon.Error("Could not find a feedback session")
  .toProperty()

subjectsStream = feedbackSessionStream
  .map (session) ->
    resUtil.findResourceLink session, "subjects", "get"
  .flatMap (url) ->
    Bacon.fromPromise reqUtil.wrapRequest client.api(url, "get")
  .map R.prop('subjects')
  .flatMapError -> []
  .toProperty()

ratingsStream = feedbackSessionStream
  .map (session) ->
    resUtil.findResourceLink session, "ratings", "get"
  .flatMap (url) ->
    Bacon.fromPromise reqUtil.wrapRequest client.api(url, "get")
  .map R.prop('ratings')
  .flatMapError -> []
  .toProperty()

closeReview = d.stream('close-review')
  .map (review) -> resUtil.findResourceLink review, "self", "put"
  .flatMap (url) ->
    Bacon.fromPromise reqUtil.wrapRequest client.api(url, "put", {status: 'closed'})
  .map R.prop('rating')

tabs = userStore
    .tabs
    .map R.filter R.propEq('type', 'reviews')
    .map R.filter R.propEq('_version', Feedback.MODEL_VERSION)
    .map R.map (tab) -> new Feedback(tab)
    .map (tabs) ->
      if tabs.length == 0 and userStore.hasAnyRole('config', 'restaurant', 'channel', 'ambassador')
        [ new Feedback(id: 'inbox', name: 'Reviews') ]
      else
        tabs
    .map R.take(1)

emailSeparator = R.join "", R.map (-> "-"), R.range(1, 80)

makeReplyURL = (order, review) ->
  email = order.customer.email
  cc = encodeURIComponent "reviews@zuppler.com"
  restaurantName = order.restaurant.name
  customerName = order.customer.name
  shortId = order.id.split(/-/)[0]
  subject = encodeURIComponent "Your #{restaurantName} order ##{shortId} review"
  placeholder = "[PLACE RESPONSE HERE]"
  body = encodeURIComponent "Hi #{ customerName },\n\n#{placeholder}\n\n#{emailSeparator}\n On #{moment(review.created).format("lll")} you wrote:\n\n\t\"" + review.comment + "\""
  "mailto:#{email}?cc=#{cc}&subject=#{subject}&body=#{body}"

module.exports =
  session: feedbackSessionStream.flatMapError (error) -> null
  subjects: subjectsStream
  ratings: ratingsStream
  loading: Bacon.never()
  tabs: tabs

  makeReplyURL: makeReplyURL
  closeReviewStream: closeReview
  closeReview: (review) ->
    d.stream('close-review').push review
    closeReview
