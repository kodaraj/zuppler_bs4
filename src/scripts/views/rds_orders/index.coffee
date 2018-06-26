ReactBacon = require 'react-bacon'
React     = require 'react'
R         = require 'ramda'
createReactClass = require 'create-react-class'
OrderPage = require 'views/order/order'
uiStore = require 'stores/ui'
orderStore = require 'stores/order'
{ Route} = require 'react-router-dom'
{ Container, Col, Row } = require 'reactstrap'
Toolbar = require './toolbar'
Cards = require './cards'
SoundService = require 'components/sound'

RdsOrders = createReactClass
  displayName: 'Orders'
  mixins: [ReactBacon.BaconMixin]

  getInitialState: ->
    data: null
    order: null

  componentDidMount: ->
    @plug uiStore.current, 'data'
    @plug orderStore.current, 'order'

  render: ->
    if @state.data
      <Container fluid={true} style={paddingLeft: "0px", paddingRight: "0px"} key={@state.data.id}>
        { @renderToolbarRow() }
        <Row key={@state.data.id}>
          { @renderContentRow(@state.order) }
          <Route exact path="/rds/:listId/order/:orderId" component={OrderPage} />
        </Row>
      </Container>
    else
      null

  renderToolbarRow: ->
     <Row>
      <Col sm={12}>
        <Toolbar list={@state.data} />
      </Col>
    </Row>

  renderContentRow: (order) ->
    if @props.match.params.orderId
        @renderCards(order, 1)
    else
        @renderCards(order, 4)

  renderCards: (currentOrder, columns) ->
    width = if columns == 1 then 3 else 12
    <Col lg={width} md={width} xs={12} sm={12}>
      <Cards list={@state.data} selected={currentOrder} columns={columns} />
    </Col>

RdsOrders.getDerivedStateFromProps = (props, state) ->
  if not state.data or state.data.id != props.match.params.listId
    uiStore.setCurrentUI("rds", props.match.params.listId)
    { data: null, order: null }
  else
    null

module.exports = RdsOrders
