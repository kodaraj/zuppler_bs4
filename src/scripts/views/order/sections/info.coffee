React      = require 'react'
ReactBacon = require 'react-bacon'
R          = require 'ramda'
moment     = require 'moment'
{Icon       }= require 'react-fa'
hopUtil    = require 'utils/hop'
cx         = require 'classnames'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
Rating     = require 'components/lib/rating'
{ BaconMixin }   = ReactBacon
{ButtonGroup, Button} = require 'reactstrap'
orderUtils = require '../components/utils'
{ toID, shortID, touple, booleanOf, currency, percent } = orderUtils
{ formatTimeWithOffset, pairsToList, pairsToListItems, googleMapsLinkToAddress, Money } = orderUtils
{ GroupHeader, ExpandedStateMixin } = require '../components/group-header'
onlyWithRating = R.filter R.compose R.not, R.isNil, R.prop('rating')

pairQuestionsWithRatings = R.curry (ratings, question) ->
  rating = R.find(R.whereEq('subject_id': question.id), ratings)
  {question: question, rating: rating}

feedbackStore = require 'stores/feedback'

OrderInfo = createReactClass
  displayName: 'OrderInfo'
  mixins: [ExpandedStateMixin("sections.info.visible"), ReactBacon.BaconMixin]
  propTypes:
    order: PropTypes.object.isRequired
    locale: PropTypes.string.isRequired
    restaurant: PropTypes.object.isRequired
    events: PropTypes.array.isRequired

  getInitialState: ->
    feedbackSession: null
    subjects: []
    ratings: []
    reviewStatus: 'open'

  componentDidMount: ->
    @plug feedbackStore.session, 'feedbackSession'
    @plug feedbackStore.subjects, 'subjects'
    @plug feedbackStore.ratings, 'ratings'

    reviewStatus = feedbackStore
        .subjects
        .map(R.find(R.propEq('type', 'review')))
        .filter R.compose R.not, R.isNil
        .map(R.prop('id'))
        .combine feedbackStore.ratings, (reviewSubjectId, ratings) ->
          R.find R.propEq('subject_id', reviewSubjectId), ratings
        .filter R.compose R.not, R.isNil
        .map R.prop('status')
    @plug reviewStatus, 'reviewStatus'
    @plug feedbackStore.closeReviewStream.map(R.prop('status')), 'reviewStatus'

  _service: (pairs, order) ->
    switch order.service.id
      when 'DELIVERY'
        amount = null
        if order.totals.charges.delivery > 0
          amount = <span key="amount" className="label label-info"><Money amount={order.totals.charges.delivery} locale={@props.locale}/></span>
        pairs = R.concat pairs, touple order.service.label,
          <span>
            to {googleMapsLinkToAddress(@props.order.service.value.address)}
          </span>
        pairs = R.concat pairs, touple 'Instructions', order.service.value.instructions if order.service.value.instructions
      when 'PICKUP', 'DINEIN'
        pairs = R.concat pairs, touple order.service.label,
          <span>
            from {googleMapsLinkToAddress(order.service.value.location)}
          </span>
      when 'CURBSIDE'
        pairs = R.concat pairs, touple order.service.label,
          <span>
            with <span key="car" className="label label-info"><Icon name="car" /> { order.service.value.vehicle }</span>
          </span>
      else
        pairs = R.concat pairs, touple order.service.label, <span></span>
    pairs

  _tender: (pairs, order) ->
    switch order.tender.id
      when 'CARD'
        pairs = R.concat pairs, touple 'Payment Processor', order.tender.value.as
    pairs

  _time: (pairs, order) ->
    formatTime = R.partial(formatTimeWithOffset, [@props.restaurant.timezone.offset])
    switch order.time.id
      when 'ASAP'
        pairs = R.concat pairs, touple 'Due', <span><span className="badge">ASAP</span> {formatTime(order.time.value)}</span>
      else
        pairs = R.concat pairs, touple 'Due', formatTime(order.time.value)

  _customer_data: (p, order) ->
    o = order
    pairs = []
    # pairs = R.concat pairs, touple 'Extra Order Settings', <span></span>
    pairs = R.concat pairs, touple 'Catering', booleanOf o.settings.catering if o.settings.catering

    pairs = R.reduce (accum, group) ->
      R.concat accum, touple group.group_name, "" unless group.group_name is "_none_"
      R.reduce (accum, data) ->
        R.concat accum, touple data.name || "Info", data.value || ""
      , accum, group.data
    , pairs, o.settings.extra_fields
    if pairs.length > 0
      p = R.concat p, pairs
    p

  _feedbackAverage: (p, order) ->
    pairs = []
    if @state.feedbackSession
      ratings = @state.ratings
      subjects = @state.subjects
      pairs = R.concat pairs, touple "Order Rating", React.createElement(Rating, {"score": (@state.feedbackSession.average)}) if @state.feedbackSession.average > 0

      review = R.find(R.whereEq(type: 'review'), @state.subjects)
      rating = if review then R.find(R.whereEq(subject_id: review.id), ratings) else null

      if rating and rating.comment
        pairs = R.concat pairs, touple "Customer Review",
        <div>
           <div style={textAlign: "justify", fontFamily: "monospace", fontSize: "small", backgroundColor: "#eee", padding: "0.5em 1em", border: "1px dashed #999"}>{rating.comment}</div>
           {@_reviewButtons(order, review, rating)}
        </div>

      questions = R.filter(R.whereEq(type: 'question'), subjects)

      questionResponses = onlyWithRating R.map pairQuestionsWithRatings(ratings), questions

      pairs = R.reduce (accum, questionRating) ->
        R.concat accum, touple <span key={questionRating.question.id}><Icon name="question-circle"/> {questionRating.question.name}</span>, questionRating.rating.score
      , pairs, onlyWithRating(questionResponses)

    if pairs.length > 0
      p = R.concat p, pairs

    p

  clickButton: (order, rating) ->
    window.location.href =  feedbackStore.makeReplyURL(order, rating)

  _reviewButtons: (order, review, rating) ->
    if @state.reviewStatus == 'open'
      <div style={height: "1em"}>
        <div className="pull-right">
            <ButtonGroup>
              <Button size="sm" color="warning" onClick = {() => @clickButton(order,rating)} target="_blank"><Icon name="reply" /> Reply User Review</Button>
              <Button size="sm" color="success" onClick={() => R.partial @onMarkReviewComplete, [rating]}><Icon name="archive" /> Mark Completed</Button>
            </ButtonGroup>
        </div>
      </div>

  onMarkReviewComplete: (rating) ->
    feedbackStore.closeReview(rating)

  render: ->
    o = @props.order
    formatTime = R.partial(formatTimeWithOffset, [@props.restaurant.timezone.offset])

    pairs = [
      ['Code', <span><Icon name="qrcode" /> {o.code}</span> ]
    ]

    pairs = R.concat pairs, touple 'Placed', formatTime(o.placed_at)
    if o.time and o.time.estimation
      e = o.time.estimation
      pairs = R.concat pairs, touple 'Fire time', formatTime(e.fire) if e.fire
      pairs = R.concat pairs, touple 'Pickup time', formatTime(e.pickup) if e.pickup
      pairs = R.concat pairs, touple 'Delivery time', formatTime(e.delivery) if e.delivery
    pairs = @_time(pairs, o)

    pairs = @_service(pairs, o)
    pairs = @_tender(pairs, o)

    pairs = @_customer_data(pairs, o)

    pairs = @_feedbackAverage(pairs, o)

    pairsToList "order_info", pairs, header: React.createElement("span", {"key": "label"}, "Order Info")

    <ul className="list-group">
      <GroupHeader title="Order Info" expanded={@isExpanded()} onToggleExpandState={@onToggleExpandState}>
      </GroupHeader>
      <span className={@expandedToClassName()}>
        {pairsToListItems("order_info", pairs, key: @props.restaurant.permalink)}
      </span>
    </ul>

module.exports = OrderInfo
