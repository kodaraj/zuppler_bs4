ReactBacon = require 'react-bacon'
React     = require 'react'
R         = require 'ramda'
createReactClass = require 'create-react-class'
OrderPage = require 'views/order/order'
uiStore = require 'stores/ui'
orderStore = require 'stores/order'

{ Route } = require 'react-router-dom'
{ Row, Col, Container } = require 'reactstrap'

Toolbar = require './toolbar'
Cards = require './cards'

SoundService = require 'components/sound'

Orders = createReactClass
  displayName: 'Orders'
  mixins: [ReactBacon.BaconMixin]

  getInitialState: ->
    data: null
    order: null

  componentDidMount: ->
    @plug uiStore.current.filter(R.propEq('type', "lists")), 'data'
    @plug orderStore.current, 'order'

  render: ->
    if @state.data
      <div key={@state.data.id}>
        { @renderToolbarRow() }
          <Row key={@state.data.id}>
            { @renderContentRow(@state.order) }
            <Route exact path="/lists/:listId/order/:orderId" component={OrderPage} />
          </Row>
      </div>
    else
      null

  renderToolbarRow: ->
    <Toolbar list={@state.data} />

  renderContentRow: (order) ->
    if @props.match.params.orderId
      <Col md={3}>
        {@renderCards(order, 1)}
      </Col>
    else
      @renderCards(order, 4)

  renderCards: (currentOrder, columns) ->
    <Cards list={@state.data} selected={currentOrder} columns={columns} />

Orders.getDerivedStateFromProps = (props, state) ->
  if not state.data or state.data.id != props.match.params.listId
    uiStore.setCurrentUI("lists", props.match.params.listId)
    { data: null, order: null }
  else
    null

{ withRouter } = require 'react-router'
module.exports = withRouter(Orders)
