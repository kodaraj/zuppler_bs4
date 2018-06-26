ReactBacon = require 'react-bacon'
React      = require 'react'
R          = require 'ramda'
{ Icon }= require 'react-fa'
cx = require 'classnames'
uuid = require 'uuid'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
uiStore = require 'stores/ui'
cartsStore = require 'stores/carts'
userStore = require 'stores/user'
{ withRouter } = require 'react-router-dom'
{ Nav, NavItem, Label, NavLink } = require 'reactstrap'

filterTabs = (stream, type) ->
  stream
    .map R.filter R.propEq('type', type)

renderList = (title, list, itemRender, addUrl, expanded, version = 0) ->
  expandedClass = cx "text-justify", 'hidden': !expanded
  showAdd = cx 'hidden': !addUrl
  <div>
    <div className={expandedClass}>
      <a className={showAdd} href={addUrl} className="btn btn-default btn-sm btn-block" role="button">
        <Icon name="search-plus" /> Create List
      </a>
      <div className="list-title"><span>{ title }</span></div>
    </div>
    <Nav key={version} pills vertical>
      { R.map itemRender, list }
    </Nav>
  </div>

iconForTabType = (type) ->
  switch type
    when 'lists' then 'list'
    when 'rdsLists' then 'list-alt'
    when 'reviews' then 'comments'
    when 'carts' then 'shopping-cart'
    when 'orders' then 'shopping-cart'


Sidebar = createReactClass
  displayName: 'Sidebar'

  propTypes:
    expanded: PropTypes.bool.isRequired

  mixins: [ ReactBacon.BaconMixin ]

  getInitialState: ->
    lists: []
    reviews: []
    rdsLists: []
    tabs: []
    carts: []
    orders: []
    current: null
    cart: null # don't remove as current cart needs at least one listener
    version: 0

  componentDidMount: ->
    @plug filterTabs(uiStore.active, "lists"), 'lists'
    @plug filterTabs(uiStore.active, "rdsLists"), 'rdsLists'
    @plug filterTabs(uiStore.active, "orders"), 'orders'
    @plug filterTabs(uiStore.active, "reviews"), 'reviews'
    @plug filterTabs(uiStore.active, "carts"), 'carts'

    @plug uiStore.active, "tabs"

    @plug uiStore.current, 'current'
    @plug cartsStore.current, 'cart'

    @plug uiStore.version, 'version'

  onCreateCart: ->
    newCartUUID = uuid()
    cartsStore.createCart newCartUUID
    @props.history.push "/carts/#{newCartUUID}"

  render: ->
    <div>
      { @renderLists() }
      { @renderRdsLists() }
      { @renderOrders() }
      { @renderPendingOrders() }
      { @renderReviews() }
    </div>

  renderLists: ->
    if @state.lists.length > 0
      renderList "Orders", @state.lists, @renderTab, "#/lists/new", @props.expanded, @state.version

  renderRdsLists: ->
    if @state.rdsLists.length > 0
      renderList "RDS Orders", @state.rdsLists, @renderTab, "#/rds/new", @props.expanded, @state.version

  renderOrders: ->
    if @state.orders.length > 0
      renderList "Pinned Orders", @state.orders, @renderTab, null, @props.expanded, @state.version

  renderReviews: ->
    if @state.reviews.length > 0
      <Nav pills vertical>
        { R.map @renderTab, @state.reviews }
      </Nav>

  renderPendingOrders: ->
    return null unless userStore.hasRole 'config'
    expandedClass = cx "text-justify", 'hidden': !@props.expanded
    orderListClass = cx "list-title", "hidden": @state.carts.length == 0

    if @props.expanded
      <div>
        <div className={expandedClass}>
          <a href="#/carts/new" className="btn btn-default btn-sm btn-block" role="button">
            <Icon name="search-plus" /> Create New Order
          </a>
          <div className={ orderListClass }><span>Pending Orders</span></div>
        </div>
        <Nav pills vertical>
          { R.map @renderTab, @state.carts }
        </Nav>
      </div>
    else
      <ul className="nav nav-pills nav-stacked">
        <li role="presentation">
          <a role="button" href="#/carts">
            <Label>
              <Icon name="shopping-cart" />
            </Label>
          </a>
        </li>
      </ul>

  renderTab: (tab) ->
    activeKey = R.path(['current', 'id'], @props)

    <NavItem key={tab.id} active={activeKey} >
      <NavLink href="#/#{tab.type}/#{tab.id}">
        <ListButton key={tab.id} tab={tab} expanded={@props.expanded} />
      </NavLink>
    </NavItem>

SoundService = require 'components/sound'

initials = R.pipe(R.split(/\s+/), R.map(R.nth(0)), R.join(""))

ListButton = createReactClass
  displayName: 'TabButton'

  mixins: [ReactBacon.BaconMixin]

  propTypes:
    tab: PropTypes.object.isRequired
    expanded: PropTypes.bool.isRequired

  getInitialState: ->
    loading: false
    activity: false
    changes: null
    meta: null

  componentDidMount: ->
    @plug @props.tab.loading, 'loading' if @props.tab.loading
    @plug @props.tab.activity, 'activity' if @props.tab.activity
    @plug @props.tab.meta, 'meta' if @props.tab.meta

  render: ->
    if @props.expanded
      <div style={wrap: "no", overflowX: "hidden"}>
        <span className="pull-right">{@renderInfo()}</span>
        <Icon name={iconForTabType(@props.tab.type)}/>
        {' '}{@props.tab.name}
        <SoundService soundStream={@props.tab.noise} />
      </div>
    else
      labelStyle = if @state.activity then "danger" else "default"
      <span>
        <Label color={labelStyle}>{ initials(@props.tab.name) }<br/>{@renderInfoText()}</Label>
        <SoundService soundStream={@props.tab.noise} />
      </span>

  renderInfoText: ->
    if @state.loading
      "??"
    else if @state.meta
      @state.meta.total

  renderInfo: ->
    if @state.loading
      <Icon key="loading" name="spinner" spin={true} fixedWidth={true}  className="pull-right" />
    else if @state.meta
      labelStyle = if @state.activity then "danger" else "default"
      <Label key="total" color={labelStyle} className="pull-right">
        {@state.meta.total}
      </Label>
    else if @state.activity
      labelStyle = if @state.activity then "danger" else "hidden"
      <Label key="active" color={labelStyle} className="pull-right">*</Label>
    else null


module.exports = withRouter(Sidebar)
