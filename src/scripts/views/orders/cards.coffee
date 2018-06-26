React = require 'react'
ReactBacon = require 'react-bacon'
{Icon }= require 'react-fa'
R = require 'ramda'
cx = require 'classnames'
NavigationMixin = require 'components/lib/navigation'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
{withRouter} = require 'react-router-dom'
moment = require 'moment'
orderStore = require 'stores/order'
presenceStore = require 'stores/presence'
{ Card, CardBody, CardHeader, CardFooter, CardColumns, CardLink, CardGroup } = require 'reactstrap'
ReactBacon = require 'react-bacon'
{ timeSlice } = require 'utils/time'
import Pagination from "react-js-pagination"

{ BaconMixin } = ReactBacon

{ shorten } = require 'zuppler-js/lib/utils/text'

Cards = createReactClass
  displayName: 'Cards'

  propTypes:
    list: PropTypes.object.isRequired
    selected: PropTypes.object
    columns: PropTypes.number.isRequired

  render: ->
    <div>
      {@renderOrders()}
      {@renderPagination()}
    </div>

  renderOrders: ->
    <ListOrders list={@props.list} selected={@props.selected} columns={@props.columns}/>

  renderPagination: ->
    <MetaPagination list={@props.list} />


ListOrders = createReactClass
  displayName: 'ListOrders'
  propTypes:
    list: PropTypes.object.isRequired
    selected: PropTypes.object
    columns: PropTypes.number.isRequired

  mixins: [BaconMixin]

  getInitialState: ->
    orders: []
    ordersToUsers: {}

  componentDidMount: ->
    @plug @props.list.orders, 'orders'
    @plug presenceStore.orders, 'ordersToUsers'

  render: ->
    if @props.columns > 1
      <CardColumns>
        {R.map @renderCard, @state.orders}
      </CardColumns>
    else
      <Card>
        {R.map @renderCard, @state.orders}
      </Card>

  renderCard: (order) ->
    active = @props.selected and @props.selected.id == order.id
    users = @state.ordersToUsers[order.id] || []
    <OrderCard key={order.id} order={order} users={users} active={active} list={@props.list}></OrderCard>

OrderCard = createReactClass
  displayName: 'OrderCard'
  mixins: [ReactBacon.BaconMixin]
  propTypes:
    list: PropTypes.object.isRequired
    order: PropTypes.object.isRequired
    users: PropTypes.array
    active: PropTypes.bool

  onOpenOrder: ->
    @props.history.push "/lists/#{@props.list.id}/order/#{@props.order.id}"

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
      { @renderStateIcon(@props.order.state) } { @renderPendingStateIcon(@props.order.pending) } { shorten @props.order.restaurant_name, 40, true }
    </div>

  renderFooter: (users) ->
    timeInfo = moment(@props.order.time).fromNow()
    placedInfo = moment(@props.order.placed).fromNow()
    orderId = @props.order.id.split('-')[0]
    <span className="card-footer">
      <span key="p">{ @renderTenderIcon(@props.order.tender_id) } {(@props.order.total / 100).toFixed(0)}</span>
      <span key="c"><Icon name="clock-o" /> { timeInfo }</span>
      <span key="t"><Icon name="ticket" /> { orderId }</span>
      <span className="presence-info">{users}</span>
    </span>

  renderTenderIcon: (tender) ->
    switch tender
      when 'CASH', 'CARD_ON_DELIVERY', 'COD' then React.createElement(Icon, {"name": "money", "title": (tender)})
      when 'CARD', 'LEVELUP' then React.createElement(Icon, {"name": "credit-card", "title": (tender)})
      when 'BUCKID', 'ACCOUNT' then React.createElement(Icon, {"name": "google-wallet", "title": (tender)})
      when 'POINTS' then React.createElement(Icon, {"name": "dot-circle-o", "title": (tender)})
      when 'PAYPAL' then React.createElement(Icon, {"name": "paypal", "title": (tender)})
      when 'MOLLIE' then React.createElement(Icon, {"name": "cc-paypal", "title": (tender)})
      else React.createElement(Icon, {"name": "question-mark", "title": (tender)})

  renderStateIcon: (state) ->
    switch state
      when 'confirmed' then React.createElement(Icon, {"name": "check", "title": (state)})
      when 'invoiced' then React.createElement(Icon, {"name": "check-circle-o", "title": (state)})
      when 'missed' then React.createElement(Icon, {"name": "exclamation", "title": (state)})
      when 'canceled' then React.createElement(Icon, {"name": "remove", "title": (state)})
      when 'editing' then React.createElement(Icon, {"name": "pencil-square-o", "title": (state)})
      when 'captured' then React.createElement(Icon, {"name": "plus", "title": (state)})
      when 'executing' then React.createElement(Icon, {"name": "shopping-cart", "title": (state)})
      when 'created' then React.createElement(Icon, {"name": "plus-square-o", "title": (state)})
      when 'rejected' then React.createElement(Icon, {"name": "ban", "title": (state)})
      else React.createElement("span", null, React.createElement(Icon, {"name": "info"}), " ", ( state ))

  renderPendingStateIcon: (pending) ->
    if pending then React.createElement(Icon, {"name": "code-fork", "title": "Processing..."}) else null

  render: ->
    initials = R.compose(R.join(""), R.map((str)-> str.substring(0, 1)), R.split(/\s+/))
    roleToClass = R.map (n) -> "presence-role-#{n}"

    users = @props.users.map (u) ->
      className = cx "label", "label-default", roleToClass(u.roles).join(" ")
      <span key={u.email} className={className} title={u.user}>{initials u.user || "N A"}</span>

    <Card key={@props.order.id} className={@orderStateClass()}>
      <CardLink href= "#/lists/#{@props.list.id}/order/#{@props.order.id}">
        <CardHeader>
          {@renderHeader()}
        </CardHeader>
        <CardBody>
          <span key="name" className="customer-name">{@props.order.customer_name}</span>
          <span key="sid" className="order-type">{@props.order.service_id}</span>
        </CardBody>
        <CardFooter>
          {@renderFooter(users)}
        </CardFooter>
      </CardLink>
    </Card>

MetaPagination = createReactClass
  displayName: 'MetaPagination'
  mixins: [BaconMixin]
  propTypes:
    list: PropTypes.object.isRequired

  getInitialState: ->
    meta:
      count: 0
      total: 0
      page: 0

  componentDidMount: ->
    @plug @props.list.meta, 'meta'

  selectPage: (pageNumber) ->
    @props.list.setPage pageNumber

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

module.exports = withRouter(Cards)
