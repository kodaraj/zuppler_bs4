R = require 'ramda'
React = require 'react'
ReactBacon = require 'react-bacon'
cx = require 'classnames'
{ Icon }= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'


moment = require "moment"

import {FormGroup, Label, Input, DropdownItem, ButtonDropdown} from 'reactstrap'
DateRangePicker = require 'react-bootstrap-daterangepicker'

restaurantStore = require 'zuppler-js/lib/stores/restaurant'
userStore = require 'zuppler-js/lib/stores/user'

SettingSectionMixin =
  getInitialState: ->
    active: false
    available: []
    selected: null
    value: null
    messages:
      errors: []
      info: []

  componentDidMount: ->
    section = @props.section
    @plug section.active, 'active'
    @plug section.available, 'available'
    @plug section.selected, 'selected'
    @plug section.errors, 'messages'
    @plug section.value, 'value'

  changeSelection: (selection) ->
    section = @props.section
    section.setSelection selection
    @setState selected: selection

  changeValue: (value) ->
    section = @props.section
    section.setValue value
    @setState value: value

  renderMessages: ->
    errors = R.defaultTo [], R.prop('errors', @state.messages)
    info = R.defaultTo [], R.prop('info', @state.messages)

    renderMessage = R.curry (className, msg) -> React.createElement("div", {"className": (className)}, (msg))
    renderError = renderMessage 'text-danger'
    renderInfo = renderMessage 'text-warning'

    if errors.length + info.length
      R.flatten [ R.map(renderError, errors), R.map(renderInfo, info) ]

  cartValidationState: ->
    if @state.messages.errors.length
      "error"
    else if @state.messages.info.length
      "warning"
    else
      "success"


Tender = createReactClass
  displayName: 'Tender'
  mixins: [ReactBacon.BaconMixin, SettingSectionMixin ]

  onChangeSelection: (key) ->
    @changeSelection R.find R.propEq('id', key), @state.available

  onChangeValue: (event) ->
    @changeValue event.target.value

  render: ->
    if @state.active
      console.log "Tender", @state.selected, @state.available
      <FormGroup controlId="tender" validationState={@cartValidationState()}>
        <Label>Payment</Label>
        <Input>
          <ButtonDropdown componentClass={InputGroup.Button} id="pay-type"
            title={@state.selected.name || '??'} onClick={@onChangeSelection}>
            { R.map @renderMenuItem, @state.available }
          </ButtonDropdown>
          { @renderValueInput() }
        </Input>
        <HelpBlock><small>{@renderMessages()}</small></HelpBlock>
      </FormGroup>
    else
      null

  renderValueInput: ->
    if @state.selected.id is 'BUCKID' or @state.selected.id is 'ACCOUNT'
      <Input type="text" value={@state.value} onChange={@onChangeValue} placeholder="enter code..."/>

  renderMenuItem: (option) ->
    <DropdownItem key={option.id} key={option.id}>{option.name || option.label}</DropdownItem>


Tip = createReactClass
  displayName: 'Tip'
  mixins: [ReactBacon.BaconMixin, SettingSectionMixin ]

  onChangeSelection: (key) ->
    @changeSelection R.find R.propEq('id', key), @state.available

  onChangeValue: (event) ->
    @changeValue R.max @state.selected.min, parseInt event.target.value

  render: ->
    if @state.active
      <FormGroup controlId="tip" validationState={@cartValidationState()}>
        <Label>Tip</Label>
        <Input>
          <ButtonDropdown componentClass={InputGroup.Button} id="tip-type"
            title={@state.selected.label || '??'} onClick={@onChangeSelection}>
            { R.map @renderMenuItem, @state.available }
          </ButtonDropdown>
          <Input type="number" value={@state.value} onChange={@onChangeValue}/>
        </Input>
        <HelpBlock><small>{@renderMessages()}</small></HelpBlock>
      </FormGroup>
    else
      null

  renderMenuItem: (option) ->
    <DropdownItem key={option.id} key={option.id}>{option.name || option.label}</DropdownItem>

convertTime = (dateTimeString) ->
  moment(dateTimeString).format("YYYY-MM-DD HH:mm")

Time = createReactClass
  displayName: 'Time'
  mixins: [ReactBacon.BaconMixin, SettingSectionMixin ]

  onChangeSelection: (key) ->
    @changeSelection R.find R.propEq('id', key), @state.available

  onChangeValue: (event, picker) ->
    dateTime = picker.startDate.toDate()
    @changeValue convertTime dateTime

  orderTime: ->
    if typeof @state.value == 'string'
      moment(@state.value, "YYYY-MM-DD HH:mm").toDate()
    else if typeof @state.value == 'object'
      @state.value
    else
      new Date

  render: ->
    if @state.active
      orderTime = @orderTime()
      # console.log "orderTime", @state.value, orderTime
      timePickerClass = cx "hidden": @state.selected.id isnt 'SCHEDULE'
      <FormGroup controlId="tip" validationState={@cartValidationState()}>
        <Label>Time</Label>
        <Input>
          <ButtonDropdown componentClass={InputGroup.Button} id="time-type"
            title={@state.selected.label || '??'} onClick={@onChangeSelection}>
            { R.map @renderMenuItem, @state.available }
          </ButtonDropdown>
          <DateRangePicker onApply={@onChangeValue} opens="right" drops="down"
            minDate={moment()} startDate={moment(orderTime)} singleDatePicker={true} timePickerIncrement={10}
            showDropdowns={true} showWeekNumbers={true} timePicker={true}
            buttonClasses={['btn', 'btn-sm']} applyClass={'btn-primary'} cancelClass={'btn-default'}>
            <Input className={timePickerClass} type="text" readOnly value={moment(orderTime).format("LLL")} />
          </DateRangePicker>
        </Input>
        <HelpBlock><small>{@renderMessages()}</small></HelpBlock>
      </FormGroup>
    else
      null

  renderMenuItem: (option) ->
    <DropdownItem key={option.id} key={option.id}>{option.name || option.label}</DropdownItem>

OrderType = createReactClass
  displayName: 'OrderType'

  mixins: [ReactBacon.BaconMixin, SettingSectionMixin ]

  getInitialState: ->
    userAddresses: []

  onChangeSelection: (key) ->
    @changeSelection R.find R.propEq('id', key), @state.available

  onChangeValue: (event) ->
    @changeValue event.target.value

  valueCompForSelection: (id) ->
    switch id
      when 'DELIVERY'
        OrderTypeDelivery
      when 'PICKUP'
        OrderTypePickup
      else
        NullComp

  render: ->
    if @state.active
      Comp = @valueCompForSelection(@state.selected.id)
      <FormGroup controlId="type" validationState={@cartValidationState()}>
        <Label>Order For</Label>
        <Input>
          <ButtonDropdown componentClass={InputGroup.Button} id="order-type"
            title={@state.selected.name || '??'} onClick={@onChangeSelection}>
            { R.map @renderMenuItem, @state.available }
          </ButtonDropdown>
          <Comp value={@state.value} onChange={@onChangeValue} />
        </Input>
        <HelpBlock><small>{@renderMessages()}</small></HelpBlock>
      </FormGroup>
    else
      null

  renderMenuItem: (option) ->
    <DropdownItem key={option.id} key={option.id}>{option.name || option.label}</DropdownItem>

NullComp = createReactClass
  displayName: 'NullComp'
  render: -> null

OrderTypeDelivery = createReactClass
  displayName: 'OrderTypeDelivery'

  mixins: [ReactBacon.BaconMixin]

  props:
    value: PropTypes.any
    onChange: PropTypes.func.isRequired

  getInitialState: ->
    userAddresses: []

  componentDidMount: ->
    @plug userStore.addresses, 'userAddresses'

  render: ->
     <Input type="select" value={@props.value.id || @props.value} onChange={@props.onChange}>
      { R.map @renderOption, @state.userAddresses }
    </Input>

  renderOption: (option) ->
    <option key={option.id} value={option.id}>{option.mini}</option>

OrderTypePickup = createReactClass
  displayName: 'OrderTypePickup'

  mixins: [ReactBacon.BaconMixin]

  props:
    value: PropTypes.any
    onChange: PropTypes.func.isRequired

  getInitialState: ->
    restaurant:
      locations: []

  componentDidMount: ->
    @plug restaurantStore.restaurant, 'restaurant'

  render: ->
    <Input type="select" value={@props.value.id || @props.value} onChange={@props.onChange}>
      { R.map @renderOption, @state.restaurant.locations }
    </Input>

  renderOption: (option) ->
    <option key={option.id} value={option.id}>{option.name}</option>

module.exports =
  Tip: Tip
  Tender: Tender
  Time: Time
  OrderType: OrderType
