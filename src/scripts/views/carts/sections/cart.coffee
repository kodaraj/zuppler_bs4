InputR = require 'ramda'
Bacon = require 'baconjs'
React = require 'react'
ReactBacon = require 'react-bacon'
cx = require 'classnames'
{ Icon }= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
RS = require 'reactstrap'

{ findResourceLink } = require 'zuppler-js/lib/utils/resources'

validate = require "validate.js"

import {Grid, Col, Row, CardBody, CardTitle, CardHeader, TabPane, TabContent, Button, Form, FormGroup, ListGroup, ListGroupItem, ButtonGroup, Nav, NavItem, NavLink} from 'reactstrap'

portalStore = require 'zuppler-js/lib/stores/portal'
restaurantStore = require 'zuppler-js/lib/stores/restaurant'
itemStore = require 'zuppler-js/lib/stores/item'
cartStore = require 'zuppler-js/lib/stores/cart'
cartItemsStore = require 'zuppler-js/lib/stores/cart/items'
menuStore = require 'zuppler-js/lib/stores/menu'

uiStore = require 'stores/ui'
cartsStore = require 'stores/carts'

Money = require 'components/money'

MenuItem = require './popup'

Card = createReactClass
  displayName: 'CartCard'

  mixins: [ReactBacon.BaconMixin, require('zuppler-js/lib/utils/bacon-observe-mixin')]

  props:
    cart: PropTypes.object.isRequired
    onChangeSection: PropTypes.func

  getInitialState: ->
    cart: null
    menu: null
    restaurant: null
    integration: null
    items: null

  componentDidMount: ->
    @plug portalStore.current, 'integration'
    @plug restaurantStore.restaurant, 'restaurant'
    @plug cartStore.cart, 'cart'
    @plug cartItemsStore.items, 'items'
    @observeStream @props.cart.integration, @setIntegrationRestaurant

  setIntegrationRestaurant: (integration) ->
    portalStore.setCurrent integration if integration

  render: ->
    return null if !@state.cart
    className = cx "panel-success": !!@state.items.length > 0, 'panel-danger': !@state.items.length
    onClick = R.partial @props.onChangeSection, ['cart']
    <RS.Card className={className} onClick={onClick} >
      <CardHeader>{@renderHeader()}</CardHeader>
      <CardBody>
        { @renderContent() }
      </CardBody>
    </RS.Card>


  renderContent: ->
    if @state.items.length
      @renderCartItems()
    else
      @renderNoItems()

  renderCartItems: ->
    <div>
      <ListGroup>
        { R.map @renderCartItem, @state.items }
      </ListGroup>
      <strong>Total: <Money value={@state.cart.total} nullLabel="empty cart" /></strong>
    </div>

  renderCartItem: (item) ->
    <ListGroupItem>{item.quantity} x { item.name } <Money value={item.price}/></ListGroupItem>

  renderNoItems: ->
    <small>No items into the cart</small>

  renderHeader: ->
    if @state.restaurant
      <div>These items:</div>

Editor = createReactClass
  displayName: 'CartEditor'

  mixins: [ ReactBacon.BaconMixin, require('zuppler-js/lib/utils/bacon-observe-mixin') ]

  props:
    cart: PropTypes.object.isRequired
    onClose: PropTypes.func.isRequired

  getInitialState: ->
    menu: null
    restaurant: null
    categories: []
    allItems: []
    filter: ""
    activeItem: null
    cartItems: []
    cartActiveItem: null
    menus: []
    activeTab: null
    cartActivity: false

  componentDidMount: ->
    @plug portalStore.current, 'integration'
    @plug restaurantStore.restaurant, 'restaurant'
    @plug menuStore.menus, 'menus'
    @plug menuStore.categories, 'categories'
    @plug menuStore.allItems, 'allItems'
    @plug cartItemsStore.items, 'cartItems'
    @observeStream menuStore.menus, @setDefaultTab
    activity = Bacon.mergeAll itemStore.loading, cartStore.loading
    @plug activity, 'cartActivity'

  setDefaultTab: (menus) ->
    if menus.length
      @setState activeTab: menus[0].id, activeItem: null

  onChangeFilter: (event) ->
    @setState filter: event.target.value
    menuStore.filter.push event.target.value

  onOpenItem: (item) ->
    @setState activeItem: item

  onCloseItem: ->
    @setState activeItem: null, cartActiveItem: null

  onEditItem: (cartItem) ->
    # finder = R.whereEq(name: cartItem.name, category: { id: cartItem.menu_category_id })

    finder = R.curry (name, categoryId, item) ->
      item.name == name and item.category.id == categoryId

    menuItem = R.find finder(cartItem.name, cartItem.menu_category_id), @state.allItems

    if menuItem and cartItem
      @setState activeItem: menuItem, cartActiveItem: cartItem
    else
      alert("Cannot find the item in the cart anymore")

  onUpdateQuantity: (item, adjustBy) ->
    cartItemsStore.updateQuantity item, R.clamp 1, 999, item.quantity + adjustBy

  onRemoveItem: (item) ->
    cartItemsStore.remove item

  onChangeTab: (tabId) ->
    @setState activeTab: tabId, activeItem: null, cartActiveItem: null
    menu = R.find R.propEq('id', tabId), @state.menus
    menuStore.setCurrentMenu menu if menu

  componentWillUnmount: ->
    menuStore.filter.push ""

  render: ->
    <Nav tabs onClick={@onChangeTab} id="menus">
      <NavItem>
        <NavLink key="cart">{@renderCartItemsTabTitle()}</NavLink>
      </NavItem>
      {@state.menus.map((menu) =>
          <NavItem>
            <NavLink key={menu.id}>
              {menu.name}
            </NavLink>
          </NavItem>
      )}
    </Nav>
    <TabContent activeTab = {@state.activeTab}>
      <TabPane disabled={@state.cartItems.length == 0}>
        <Row>
          { @renderCartItems() }
          { @renderCartActiveItem() }
        </Row>
      </TabPane>
      {@state.menus.map((menu) =>
        <TabPane>
          <Row>
            { @renderMenuContent(menu) }
            { @renderActiveItem() }
          </Row>
        </TabPane>
      )}
    </TabContent>

  renderCartItemsTabTitle: ->
    if @state.cartActivity
      <span><Icon name="spinner" spin={true}/> Cart Items</span>
    else
      <span>Cart Items</span>


  renderMenuContent: (menu) ->
    width = if @state.activeItem then 5 else 12
    if @state.categories.length > 0
      <Col md={width} lg={width}>
        { @renderSearchItems() }
        { R.map @renderCategory, @state.categories }
      </Col>
    else
      <Col md={width} lg={width}>
        { @renderSearchItems() }
        <strong>Nothing available...</strong>
      </Col>

  renderSearchItems: ->
    <FormGroup controlId="menuItem">
      <Input type="text" value={@state.filter} placeholder="search items"
        onChange={@onChangeFilter} />
    </FormGroup>

  renderActiveItem: ->
    width = if @state.activeItem then 7 else 12
    if @state.activeItem
      <Col md={width} lg={width}>
        <MenuItem key={@state.activeItem.id} menuItem={@state.activeItem} onFinish={@onCloseItem}/>
      </Col>

  renderCartActiveItem: ->
    width = if @state.activeItem then 7 else 12
    if @state.activeItem and @state.cartActiveItem
      <Col md={width} lg={width}>
        <MenuItem key={@state.cartActiveItem.id} menuItem={@state.activeItem}
          cartItem={@state.cartActiveItem} onFinish={@onCloseItem}/>
      </Col>


  renderCategory: (items) ->
    menu = items[0].menu
    category = items[0].category
    <RS.Card>
      <CardHeader>{@renderCategoryHeader(menu, category, items)}</CardHeader>
      <CardBody>
          <ListGroup>
            { R.map @renderItem, items }
          </ListGroup>
      </CardBody>
    </RS.Card>

  renderCategoryHeader: (menu, category, items) ->
    <div>
      <div key="title">
        <strong>{ category.name }</strong>
      </div>
      <div key="desc">
        <small>{category.description} { items.length } items</small>
      </div>
    </div>

  renderItem: (item) ->
    itemStyle = if @state.activeItem is item then "success" else null
    <ListGroupItem color={itemStyle}>
      <ListGroupItemHeading>{@renderItemHeader(item)}</ListGroupItemHeading>
      { item.description }
    </ListGroupItem>


  renderItemHeader: (item) ->
    <span>
      <a onClick={R.partial @onOpenItem, [item]}>{ item.name }</a> - <Money value={item.price} nullLabel="FREE" multiplePrices={item.multiple_sizes} />
    </span>

  renderCartItems: ->
    width = if @state.activeItem then 5 else 12
    <Col md={width} lg={width}>
      <ListGroup>
        { R.map @renderCartItem, @state.cartItems }
      </ListGroup>
    </Col>

  renderCartItem: (item) ->
    <ListGroupItem>
      <ListGroupItemHeading>{@renderCartItemHeader(item)}</ListGroupItemHeading>
      { @renderModifiers(item) }
      { @renderComments(item) }
      { @renderActions(item) }
    </ListGroupItem>

  renderCartItemHeader: (item) ->
    if item.modifiers.length
      R.map @renderModifierGroup, R.toPairs R.groupBy R.prop('choice_name'), item.modifiers

  renderModifierGroup: ([choice_name, modifiers]) ->
    <div><small>{choice_name}: {R.map @renderModifier, modifiers}</small></div>

  renderModifier: (modifier) ->
    <span>{modifier.name} </span>

  renderComments: (item) ->
    <div><small><em>{item.comments}</em></small></div>

  renderActions: (item) ->
    <ButtonGroup>
      <Button size="small" onClick={R.partial @onEditItem, [item]}>Edit</Button>
      <Button size="small" onClick={R.partial @onUpdateQuantity, [item, -1]}>Less</Button>
      <Button size="small" onClick={R.partial @onUpdateQuantity, [item, 1]}>More</Button>
      <Button size="small" onClick={R.partial @onRemoveItem, [item]}>Remove</Button>
    </ButtonGroup>

module.exports =
  name: 'cart'
  Card: Card
  Editor: Editor
