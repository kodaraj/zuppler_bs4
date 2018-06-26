R = require 'ramda'
React = require 'react'
ReactBacon = require 'react-bacon'
{Icon }= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

import {Button} from 'reactstrap'

orderStore = require 'stores/rds-order'
DriverBox = require './driver_box'

CancelDelivery = createReactClass
  displayName: 'CancelDelivery'
  mixins: [ReactBacon.BaconMixin]
  propTypes:
    rdsOrder: PropTypes.object.isRequired
    order: PropTypes.object.isRequired

  getInitialState: ->
    order: null
    canceled: false

  componentDidMount: ->
    @plug orderStore.current, 'order'
    orderStore.cancelDeliveryResult.onValue (r)-> orderStore.closeOrder()

  cancelDelivery: ->
    c = confirm('Are you sure you want to cancel delivery for this order?')
    if c
      orderStore.cancelDelivery()

  render: ->
    o = @props.order
    rds = @props.rdsOrder
    if o.service.id != 'DELIVERY' || !rds || !rds.state
      null
    else
      <Button key="cancel_delivery" color="info" onClick={@cancelDelivery}><Icon name="fire-extinguisher"/> Cancel Delivery</Button>

module.exports = CancelDelivery
