React = require 'react'
ReactBacon = require 'react-bacon'
{Icon }= require 'react-fa'
R = require 'ramda'
cx = require 'classnames'
NavigationMixin = require 'components/lib/navigation'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
{ withRouter } = require 'react-router-dom'
moment = require 'moment'
orderStore = require 'stores/order'
rdsOrderStore = require 'stores/rds-order'
presenceStore = require 'stores/presence'
ReactBacon = require 'react-bacon'
{ timeSlice } = require 'utils/time'
{ Container, Row, Col, Card, CardBody, CardHeader, CardFooter, CardLink } = require 'reactstrap'
import Pagination from "react-js-pagination"

Cards = createReactClass
  displayName: 'Cards'

  propTypes:
    list: PropTypes.object.isRequired
    selected: PropTypes.object
    columns: PropTypes.number.isRequired

  render: ->
    <Container fluid={true} style={paddingLeft: "0px", paddingRight: "0px"}>
      {@renderOrders()}
      {@renderPagination()}
    </Container>

  renderOrders: ->
    <Row className="cards">
      <Col>
        <ListOrders list={@props.list} selected={@props.selected} columns={@props.columns}/>
      </Col>
    </Row>

  renderPagination: ->
    <Row>
      <Col>
        <MetaPagination list={@props.list} />
      </Col>
    </Row>


ListOrders = createReactClass
  displayName: 'ListOrders'
  propTypes:
    list: PropTypes.object.isRequired
    selected: PropTypes.object
    columns: PropTypes.number.isRequired

  mixins: [ReactBacon.BaconMixin]

  getInitialState: ->
    orders: []
    ordersToUsers: {}

  componentDidMount: ->
    @plug @props.list.orders, 'orders'
    @plug presenceStore.orders, 'ordersToUsers'

  render: ->
    { columns } = @props
    width = if columns == 1 then 3 else 12
    <Row>
    <Col sm={width}>
      <Row>
        {R.map @renderCard, @state.orders}
      </Row>
    </Col>
    </Row>

  renderCard: (order) ->
    active = @props.selected and @props.selected.id == order.id
    users = @state.ordersToUsers[order.id] || []
    width = if @props.columns == 1 then 12 else 12 / @props.columns
    <Col key={order.id} sm={12} xs={12} md={width} lg={width}>
      <OrderCard order={order} users={users} active={active} list={@props.list}></OrderCard>
    </Col>


OrderCard = createReactClass
  displayName: 'OrderCard'
  mixins: [ReactBacon.BaconMixin]
  propTypes:
    list: PropTypes.object.isRequired
    order: PropTypes.object.isRequired
    users: PropTypes.array
    active: PropTypes.bool

  onOpenOrder: ->
    orderStore.openOrder @props.order
    rdsOrderStore.openOrder @props.order

  orderStateClass: ->
    state = @props.order.state
    time = moment(@props.order.time)
    placed = moment(@props.order.placed)

    cx "panel-#{state}-#{timeSlice(time)}", 'active': @props.active

  componentDidMount: ->
    @updateInterval = setInterval @forceUpdate.bind(@), 60*1000

  componentWillUnmount: ->
    clearInterval(@updateInterval)

  renderHeader: ->
    <div>
      {@props.order.restaurant_name}
    </div>

  renderFooter: (users) ->
    timeInfo = moment(@props.order.time).fromNow()
    placedInfo = moment(@props.order.placed).fromNow()
    orderId = @props.order.id.split('-')[0]
    driver = if @props.order.metadata.rds then @props.order.metadata.rds.driver_name else ''

    <span className="card-footer">
      <span key="c"><Icon name="clock-o" /> { timeInfo }</span>
      <span key="d"><Icon name="car" /> {driver}</span>
      <span className="presence-info">{users}</span>
    </span>

  render: ->
    initials = R.compose(R.join(""), R.map((str)-> str.substring(0, 1)), R.split(/\s+/))
    roleToClass = R.map (n) -> "presence-role-#{n}"
    deliveryStatus = if @props.order.metadata.rds then @delivery_label(@props.order.metadata.rds.state) else ''

    users = @props.users.map (u) ->
      className = cx "label", "label-default", roleToClass(u.roles).join(" ")
      <span key={u.email} className={className} title={u.user}>{initials u.user || "N A"}</span>

    <Card key={@props.order.id}  className={@orderStateClass()}>
      <CardLink onClick={@onOpenOrder} href = "#/rds/#{@props.list.id}/order/#{@props.order.id}">
        <CardHeader>{@renderHeader()}</CardHeader>
        <CardBody>
          <span key="name" className="customer-name">{@props.order.customer_name}</span>
          <span key="sid" className="order-type">{deliveryStatus}</span>
        </CardBody>
        <CardFooter>{@renderFooter(users)}</CardFooter>
      </CardLink>
    </Card>

  delivery_label: (state)->
    switch state
      when 'confirmed' then 'pending driver assigment'
      when 'sent_to_acceptance' then 'pending driver acceptance'
      when 'accepted' then 'accepted'
      when 'zuppler_notified' then 'delivering'
      when 'error_state' then 'error'
      when 'delivered' then 'delivered'
      when 'delivery_canceled' then 'delivery canceled'
      else state

MetaPagination = createReactClass
  displayName: 'MetaPagination'
  mixins: [ReactBacon.BaconMixin]
  propTypes:
    list: PropTypes.object.isRequired

  getInitialState: ->
    meta:
      count: 0
      total: 0
      page: 0

  componentDidMount: ->
    @plug @props.list.meta, 'meta'

  selectPage: (event, pageInfo) ->
    @props.list.setPage pageInfo.key

  render: ->
    if @state.meta.count > 0
      <Pagination
        prevPageText='prev'
        nextPageText='next'
        firstPageText='first'
        lastPageText='last'
        itemsCountPerPage = {20}
        activePage={@state.meta.page}
        pageRangeDisplayed={3}
        onChange={@selectPage}
        totalItemsCount = {@state.meta.total}
        itemClass="page-item"
        linkClass="page-link"
      />
    else
      null

module.exports = Cards
