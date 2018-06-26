React      = require 'react'
R          = require 'ramda'
ReactBacon = require 'react-bacon'
cx         = require 'classnames'
{ withRouter, Route } = require 'react-router-dom'
userStore     = require 'stores/user'
createReactClass = require 'create-react-class'
OrderPage = require 'views/order/order'
feedbackStore = require 'stores/feedback'
orderStore = require 'stores/order'
uiStore = require 'stores/ui'
{ Row, Col } = require 'reactstrap'
Cards = require './cards'
Toolbar = require './toolbar'

Feedbacks = createReactClass
  displayname: 'Feedbacks'

  mixins: [ReactBacon.BaconMixin]

  getInitialState: ->
    data: null
    order: null
    current: null

  componentDidMount: ->
    @plug orderStore.current, 'order'
    @plug uiStore.current.filter(R.propEq('type', "reviews")), 'data'

  onOpenReview: (review) ->
    orderId = review.session.name
    @props.history.push "/reviews/inbox/order/#{orderId}"
    orderStore.openOrderById orderId
    @setState current: review

  onReloadReviews: ->
    @state.data.reloadReviews()

  render: ->
    if @state.data
      <div key={@state.data.id}>
        { @renderToolbarRow(@state.current, @state.order) }
        <Row>
          { @renderContentRow(@state.current, @state.order) }
          <Route exact path="/reviews/:selectorId/order/:orderId" component={OrderPage} />
        </Row>
      </div>
    else
      null

  renderToolbarRow: (review, order) ->
    <Toolbar model={@state.data} review={@state.current} order={@state.order} />

  renderContentRow: (review, order) ->
    if order
        <Col md={3}>
          {@renderCards(order, review, 1)}
        </Col>
    else
        <Col>
          {@renderCards(order, review, 4)}
        </Col>

  renderCards: (currentOrder, currentReview, columns) ->
    <Cards model={@state.data} selectedOrder={currentOrder}
      selectedReview={currentReview}
      columns={columns} onOpenReview={@onOpenReview} />

Feedbacks.getDerivedStateFromProps = (props, state) ->
  if not state.data or state.data.id != props.match.params.selectorId
    uiStore.setCurrentUI("reviews", props.match.params.selectorId)
    { data: null, order: null }
  else
    null

module.exports = withRouter(Feedbacks)
