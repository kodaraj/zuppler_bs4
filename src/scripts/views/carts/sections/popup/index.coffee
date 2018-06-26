Bacon = require 'baconjs'
React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'


menuStore = require 'zuppler-js/lib/stores/menu'
itemStore = require 'zuppler-js/lib/stores/item'
cartItemsStore = require 'zuppler-js/lib/stores/cart/items'
restaurantStore = require 'zuppler-js/lib/stores/restaurant'
import {Card, CardBody, CardTitle, Form, FormGroup, Button , Label, Input} from 'reactstrap'
Options = require './options'

Summary = require './summary'
QuantitySelector = require './quantity'

Money = require 'components/money'

{ Icon } = require 'react-fa'

Popup = createReactClass
  displayName: 'popup'
  mixins: [ ReactBacon.BaconMixin, require('zuppler-js/lib/utils/bacon-observe-mixin') ]

  contextTypes:
    router: PropTypes.object

  props:
    item_id: PropTypes.number.isRequired
    cart_item_id: PropTypes.number
    onFinish: PropTypes.func.isRequired

  getInitialState: ->
    item: null
    comments: ''
    sizes: []
    choices: []
    restaurant: null
    selections: []
    selectionsInfo: {}
    quantity: 1
    price: 0.0
    itemData: null
    busy: false

  componentDidMount: ->
    @plug itemStore.item, 'item'
    @plug itemStore.selections.map(R.prop('comments')), 'comments'
    @plug itemStore.sizes, 'sizes'
    @plug itemStore.selections, 'selections'
    @plug itemStore.selectionsInfo, 'selectionsInfo'
    @plug itemStore.choices, 'choices'
    @plug itemStore.errors, 'errors'
    @plug itemStore.quantity, 'quantity'
    @plug itemStore.price, 'price'
    @plug itemStore.itemData, 'itemData'

    @plug restaurantStore.restaurant, 'restaurant'

    itemStore.openItem @props.menuItem
    @observeStream Bacon.zipAsArray(itemStore.item, itemStore.sizes), @editItem if @props.cartItem

  editItem: ([item, sizes]) ->
    if @state.item and @state.sizes.length and @state.item.name == @props.menuItem.name
      itemStore.editItem @props.cartItem

  addToCart: ->
    @setState busy: true
    itemStore
      .addToCart(@state.itemData)
      .firstToPromise()
      .then @onAddSuccess, @onAddFailed

  adjustQuantity: (delta) ->
    itemStore.updateQuantity(@state.quantity + delta)

  setQuantity: (q) ->
    itemStore.updateQuantity q

  onUpdateComments: (event) ->
    itemStore.setComments event.target.value

  onAddSuccess: ->
    cartItemsStore.remove @props.cartItem if @props.cartItem
    @setState busy: false
    @props.onFinish()

  onAddFailed: ->
    @setState busy: false
    alert("Failed to add the item to cart! Please retry again later.")

  render: ->
    if @state.item
      styleName = if @state.choices.length == 0 then 'simple' else 'multiple'
      <div key={@state.item.id}>
        <Card>
          <CardBody>
            <CardTitle>{@renderTitle()}</CardTitle>
            { @renderImage(@props.menuItem.image) }
            { @renderDescription() }
            <div>
              <Form>
                <FormGroup controlId="comments">
                  <Label>Comments:</Label>
                  <Input type="text" placeholder="enter user comments" value={@state.comments} onChange={@onUpdateComments} />
                </FormGroup>
              </Form>
              { @renderActions() }
              <Summary selectionsInfo={@state.selectionsInfo} />
              { @renderLoadingOptions() }
            </div>
          </CardBody>
        </Card>

        { @renderModifiers() }
      </div>
    else
      <div>
        { @renderLoading() }
      </div>

  renderTitle: ->
    @props.menuItem.name

  renderDescription: ->
    <div key="desc">
      { @props.menuItem.description }
    </div>

  renderImage: (image) ->
    if image.active
      <img key="image" src={image.medium} />

  renderModifiers: ->
    if @isLoaded()
      <Options item={@state.item} sizes={@state.sizes} choices={@state.choices} errors={@state.errors}
        restaurant={@state.restaurant} />

  renderActions: ->
    if @isLoaded()
      buttonName = if @props.cartItem then "Update item" else "Add to cart"
      <div>
        <span className="pull-left">
          <QuantitySelector quantity={@state.quantity} adjustQuantity={@adjustQuantity}
            setQuantity={@setQuantity} />
        </span>

        <Button onClick={if @state.busy then (->) else @addToCart} color="primary" disabled={@state.busy}>
          <Icon name="shopping-cart" /> {buttonName} | <Money value={@state.price} />
        </Button>
      </div>

  renderLoadingOptions: ->
    if !@isLoaded()
      @renderLoading()

  isLoaded: ->
    @props.menuItem and @state.item and R.contains @props.menuItem.id, R.map R.prop('id'), @state.item.sizes

  renderLoading: ->
    <div>
      Loading ... Please wait
    </div>

module.exports = Popup
