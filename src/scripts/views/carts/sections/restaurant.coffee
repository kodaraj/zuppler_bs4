R = require 'ramda'
React = require 'react'
ReactBacon = require 'react-bacon'
cx = require 'classnames'
{ Icon } = require 'react-fa'
createReactClass = require 'create-react-class'

Geosuggest = require('react-geosuggest').default
PropTypes = require 'prop-types'

uiStore = require 'stores/ui'
RS = require 'reactstrap'
import { CardBody, CardTitle, Button, ButtonGroup, Form} from 'reactstrap'

portalStore = require 'zuppler-js/lib/stores/portal'
userStore = require 'zuppler-js/lib/stores/user'

Card = createReactClass
  displayName: 'RestaurantCard'

  mixins: [ReactBacon.BaconMixin]

  props:
    cart: PropTypes.object.isRequired
    onChangeSection: PropTypes.func

  getInitialState: ->
    orderTime: null
    orderType: null
    address: null
    location: null
    restaurant: null

  componentDidMount: ->
    @plug @props.cart.orderTime, 'orderTime'
    @plug @props.cart.orderType, 'orderType'
    @plug @props.cart.address,   'address'
    @plug @props.cart.location,  'location'
    @plug @props.cart.integration, 'restaurant'

  render: ->
    return null if !@state.address and !@state.location
    active = !!@state.restaurant
    className = cx "panel-success": active, "panel-warning": !active
    onClick = R.partial @props.onChangeSection, ['restaurant']

    <RS.Card onClick={onClick} className={className} key={@props.cart.id}>
      <CardBody>
        <CardTitle>{@renderHeader()}</CardTitle>
          <div key="name"><strong>{ @state.restaurant?.name || "N/A" }</strong></div>
          <div key="info"><small>{@state.restaurant?.street}, { @state.restaurant?.city }, {@state.restaurant?.country}</small></div>
      </CardBody>
    </RS.Card>

  renderHeader: ->
    <div>From restaurant</div>


importantCuisines = ['American', 'Pizza', 'Burgers', 'Sandwiches', 'Salads', 'Vegetarian',
  'Italian', 'Pasta', 'Chinese', 'Indian', 'Sushi', 'Seafood']

Editor = createReactClass
  displayName: 'RestaurantEditor'

  mixins: [ReactBacon.BaconMixin, require('zuppler-js/lib/utils/bacon-observe-mixin')]

  props:
    cart: PropTypes.object.isRequired
    onClose: PropTypes.func.isRequired

  getInitialState: ->
    orderTime: null
    orderType: null
    address: null
    location: null
    restaurant:
      permalink: null
      integration_url: null
    cuisines: []

    restaurants: null
    total: 0

    userAddresses: []
    loading: false

  componentDidMount: ->
    @plug @props.cart.orderTime, 'orderTime'
    @plug @props.cart.orderType, 'orderType'
    @plug @props.cart.address,   'address'
    @plug @props.cart.location,  'location'
    @plug @props.cart.integration, 'restaurant'

    @plug userStore.addresses, 'userAddresses'

    @plug portalStore.restaurants, 'restaurants'
    @plug portalStore.total, 'total'

    @plug portalStore.loading, 'loading'

  doSearch: ->
    address = R.find R.propEq('id', @state.address), @state.userAddresses
    portalStore.search(@state.orderType, address, @state.location, @state.orderTime, @state.cuisines)

  onSelectRestaurant: (result) ->
    @setState restaurant: result
    @props.cart.setIntegration result
    @props.onClose('cart')

  onToggleCuisine: (cuisine, event) ->
    if R.contains cuisine, @state.cuisines
      @setState cuisines: R.without cuisine, @state.cuisines
    else
      @setState cuisines: R.append cuisine, @state.cuisines

  render: ->
    searchAction = if @state.loading then null else @doSearch
    <Form>
      <ButtonGroup>
        { R.map @renderCuisineButton, importantCuisines }
      </ButtonGroup>
      <Button color="primary" disabled={@state.loading} onClick={searchAction}>
        {@renderLoadingIcon()} Search Restaurants
      </Button>
      { @renderRestaurants() }
    </Form>

  renderCuisineButton: (cuisine) ->
    style = if R.contains cuisine, @state.cuisines then 'primary' else 'default'
    <Button color={style} onClick={R.partial @onToggleCuisine, [cuisine]}>{cuisine}</Button>

  renderRestaurants: ->
    if @state.restaurants
      if @state.restaurants.length
        <div>
          <strong>Found: { @state.total }</strong>
          <div>
            { R.map @renderRestaurant, @state.restaurants }
          </div>
        </div>
      else
        <div className="error">
          We are sorry but there are no restaurants with the given parameters found!
        </div>


  renderRestaurant: (r) ->
    <RS.Card key={r.id} color={if @state.restaurant?.permalink == r.permalink then "primary" else "default"}>
      <CardBody>
        <CardTitle>{@renderHeader(r)}</CardTitle>
        { r.distance.toFixed(2) }mi - { r.street }, { r.city } { ' ' }
      </CardBody>
    </RS.Card>

  renderHeader: (r) ->
    <a onClick={R.partial @onSelectRestaurant, [r]}><Icon name="cutlery"/> { r.name }</a>

  renderLoadingIcon: ->
    if @state.loading
      <Icon name="spinner" spin={true} />

module.exports =
  name: 'restaurant'
  Card: Card
  Editor: Editor
