R = require 'ramda'
React = require 'react'
ReactBacon = require 'react-bacon'
cx = require 'classnames'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

validate = require "validate.js"

DateTime = require 'react-datetime'
moment = require 'moment'
DateRangePicker = require 'react-bootstrap-daterangepicker'

Geosuggest = require('react-geosuggest').default

uiStore = require 'stores/ui'
userStore = require 'zuppler-js/lib/stores/user'

{ googlePlaceToZupplerAddress, zupplerAddressToGeoSuggestFixture } = require 'utils/address'
RS = require 'reactstrap'
import {FormGroup, FormFeedback, Input, CardBody, CardTitle, Button, Label } from 'reactstrap'

require('utils/validate_address')(validate)

Card = createReactClass
  displayName: 'PrereqCard'

  mixins: [ReactBacon.BaconMixin]

  props:
    cart: PropTypes.object.isRequired
    onChangeSection: PropTypes.func

  getInitialState: ->
    orderTime: null
    orderType: null
    user: null

  componentDidMount: ->
    @plug @props.cart.orderTime, 'orderTime'
    @plug @props.cart.orderType, 'orderType'
    @plug userStore.user, 'user'

  render: ->
    return null if !@state.user
    active = @state.orderTime and @state.orderType
    className = cx "panel-success": active, "panel-warning": !active
    onClick = R.partial @props.onChangeSection, ['prereq']

    <RS.Card key={@props.cart.id} onClick={onClick} className={className}>
      <CardBody>
        <CardTitle>{@renderHeader()}</CardTitle>
        <div key="type"><strong>{ @state.orderType || "N/A" }</strong></div>
        <div key="time"><small>{ moment(@state.orderTime).fromNow() || "N/A" }</small></div>
      </CardBody>
    </RS.Card>


  renderHeader: ->
    <div>Wants to order:</div>


Editor = createReactClass
  displayName: 'PrereqEditor'

  mixins: [ReactBacon.BaconMixin, require('zuppler-js/lib/utils/bacon-observe-mixin')]

  props:
    cart: PropTypes.object.isRequired
    onClose: PropTypes.func.isRequired

  getInitialState: ->
    orderTime: @defaultOrderTime()
    orderType: null
    address: null
    location: null
    availableAddresses: []
    address_mode: "none" # select | add | location

  componentDidMount: ->
    @plug @props.cart.orderTime, 'orderTime'
    @plug @props.cart.orderType, 'orderType'
    @plug @props.cart.address, 'address'
    @plug @props.cart.location, 'location'
    @plug userStore.addresses, 'availableAddresses'

    @observeStream @props.cart.orderType, @setAddressMode

  setAddressMode: (orderType) ->
    address_mode = switch orderType
      when 'DELIVERY' then 'select'
      when 'PICKUP', 'DINEIN', 'CURBSIDE' then 'location'
      else "none"
    @setState address_mode: address_mode

  onChangeOrderTime: (event, picker)->
    @setState orderTime: picker.startDate.toDate()

  onChangeOrderType: (event) ->
    if event.target.value and event.target.value is 'DELIVERY'
      address_mode = 'select'
    else
      address_mode = 'location'

    @setState orderType: event.target.value, address_mode: address_mode

  onChangeAddress: (address)->
    @setState address: address

  isValidDate: (currentDate, selectedDate) ->
    currentDate.isAfter(new Date)

  defaultOrderTime: ->
    moment().add(3, 'hours').set('minutes', 0).toDate()

  onSave: ->
    errors = validate @state, @validationSchema()
    @setState errors: errors
    if !errors
      @props.cart.setOrderType @state.orderType
      @props.cart.setOrderTime @state.orderTime
      @props.cart.setAddress @state.address
      @props.cart.setLocation if @state.location then R.pick ['label', 'location'], @state.location else null
      uiStore.saveTabs()
      @props.onClose('restaurant')

  onSelectExistingAddress: (event) ->
    address = R.find R.propEq('id', parseInt(event.target.value)), @state.availableAddresses

    if parseInt(event.target.value) is -1
      @setState address_mode: 'add', address: -1
    else if address
      @setState address: address.id
    else
      @setState address: null, address_mode: 'select'

  onAddNewAddress: (address) ->
    zupplerAddress = googlePlaceToZupplerAddress address
    if zupplerAddress.precision <= 10
      userStore
        .addAddress zupplerAddress
        .firstToPromise()
        .then @onAddNewAddressSuccess, @onAddNewAddressFail
      @setState address_mode: 'select'
    else
      alert("Please enter a street level address")

  onChangeLocation: (location) ->
    @setState location: location

  onAddNewAddressSuccess: (address) ->
    @setState address: address.id, address_mode: 'select'

  onAddNewAddressFail: (error) ->
    alert("Failed to add the address" + error)

  validationSchema: ->
    orderTime:
      presence: true
    orderType:
      presence: true
    address:
      presence: @state.orderType == 'DELIVERY'
    location:
      presence: @state.orderType != 'DELIVERY'

  getValidationState: (field) ->
    errors = validate @state, @validationSchema()
    if errors and errors[field] and errors[field].length > 0 then 'error' else 'success'

  render: ->
    if @state.orderTime is "Invalid Date"
      orderTime = new Date
    else
      orderTime = @state.orderTime

    <Form horizontal>
      <FormGroup controlId="orderTime" validationState={@getValidationState('orderTime')} >
        <Label>Order Time:</Label>
        <span className="inline-next-div">
          <DateRangePicker onApply={@onChangeOrderTime} opens="right" drops="down"
            minDate={moment()} singleDatePicker={true} timePickerIncrement={10}
            showDropdowns={true} showWeekNumbers={true} timePicker={true} isValidDate={@isValidDate}
            buttonClasses={['btn', 'btn-sm']} applyClass={'btn-primary'} cancelClass={'btn-default'}>
            <Input type="text" readOnly value={moment(orderTime).format("LLL")} />
          </DateRangePicker>
        </span>
        <FormFeedback />
      </FormGroup>

      <FormGroup controlId="orderType" validationState={@getValidationState('orderType')} >
        <Label>Order Type:</Label>
        <Input type="select" value={@state.orderType || ''} onChange={@onChangeOrderType}>
          <option value="">Select order type</option>
          <option value="DELIVERY">Delivery</option>
          <option value="PICKUP">Pickup</option>
          <option value="DINEIN">Dinein</option>
          <option value="CURBSIDE">Curbside Pickup</option>
        </Input>
        <FormFeedback />
      </FormGroup>

      { @renderAddressPicker() }
      { @renderAddAddress() }
      { @renderLocation() }

      { @renderValidationErrors(@state.errors) }

      <Button onClick={@props.onClose}>Close</Button>{ ' ' }
      <Button onClick={@onSave} color="primary">Save &amp; Continue</Button>
    </Form>

  renderAddressPicker: ->
    if @state.address_mode == "select" or @state.address_mode is "add"
      <FormGroup controlId="existingAddresses">
        <Label>Addresses:</Label>
        <Input type="select" value={@state.address || ''} onChange={@onSelectExistingAddress}>
          <option value="">Select user saved address</option>
          <option value="-1">Add new address</option>
          { R.map @renderAddressOption, @state.availableAddresses }
        </Input>
        <FormFeedback />
      </FormGroup>

  renderAddAddress: ->
    if @state.address_mode is "add"
      <FormGroup controlId="orderAddress" validationState={@getValidationState('address')} >
        <Label>Restaurants offering service to:</Label>
        <Geosuggest placeholder="enter delivery address"
          initialValue={''} inputClassName="form-control"
          onSuggestSelect={@onAddNewAddress} autoActivateFirstSuggest={true} />
        <FormFeedback />
      </FormGroup>

  renderLocation: ->
    if @state.address_mode is "location"
      label = if @state.location then @state.location.label else ''
      fixtures = if @state.location then [ @state.location ] else []
      <FormGroup controlId="orderLocation" validationState={@getValidationState('location')} >
        <Label>Restaurants offering service to:</Label>
        <Geosuggest placeholder="enter a city level location from where the user can go"
          initialValue={label} inputClassName="form-control" fixtures={fixtures}
          onSuggestSelect={@onChangeLocation} autoActivateFirstSuggest={true} />
        <FormFeedback />
      </FormGroup>

  renderAddressOption: (address) ->
    <option value={address.id}>{address.full}</option>

  renderValidationErrors: (errors) ->
    return null if !errors
    renderValidationFieldErrors = (error) ->
      <li>{ error }</li>
    <ul className="danger">
      { R.map renderValidationFieldErrors, R.flatten R.values errors }
    </ul>

module.exports =
  name: 'prereq'
  Card: Card
  Editor: Editor
