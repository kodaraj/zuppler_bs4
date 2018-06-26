R = require 'ramda'
React = require 'react'
ReactBacon = require 'react-bacon'
cx = require 'classnames'
import {Grid, Col, Row } from 'reactstrap'
createReactClass = require 'create-react-class'

ChannelUI = require './sections/channel'
UserUI = require './sections/user'
OrderSettingsUI = require './sections/prereq'
RestaurantUI = require './sections/restaurant'
CartUI = require './sections/cart'
CheckoutUI = require './sections/checkout'

cartsStore = require 'stores/carts'
uiStore = require 'stores/ui'

Index = createReactClass
  displayName: 'Cart'
  mixins: [ ReactBacon.BaconMixin ]

  getInitialState: ->
    cart: null
    section: 'info'

  componentWillMount: ->
    cartsStore.createNewCartUI
    uiStore.setCurrentUI("carts", "cartId")

  componentDidMount: ->
    @plug cartsStore.current, 'cart'

  componentWillReceiveProps: (nextProps) ->
    @setState section: 'info'

  onChangeSection: (section = 'info') ->
    uiStore.saveTabs()
    @setState section: section

  render: ->
    return @renderLoading() if !@state.cart
    sections = [ ChannelUI, UserUI, OrderSettingsUI, RestaurantUI, CartUI, CheckoutUI ]

    <Grid fluid={true} key={@state.cart.id}>
      <Row key="content">
        <Col key="side" md={4} lg={3}>
          { R.addIndex(R.map) @renderCard, sections }
        </Col>
        <Col key="content" md={8} lg={9}>
          { @renderContent(sections, @state.section) }
        </Col>
      </Row>
    </Grid>

  renderCard: (section, index) ->
    <section.Card key={index} cart={@state.cart} onChangeSection={@onChangeSection} />

  renderContent: (sections, sectionId) ->
    section = R.find R.propEq('name', sectionId), sections

    if section
      <section.Editor cart={@state.cart} onClose={@onChangeSection} />

  renderLoading: ->
    <div>Loading Order Information....</div>


module.exports = Index
