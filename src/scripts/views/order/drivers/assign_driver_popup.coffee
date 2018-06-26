R = require 'ramda'
React = require 'react'
ReactBacon = require 'react-bacon'
{Icon }= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
import {Modal, ModalTitle, ModalBody, ModalFooter, Button, Table, Alert} from 'reactstrap'
driversStore = require 'stores/drivers'
orderStore = require 'stores/rds-order'
DriverBox = require './driver_box'

AssignDriverPopup = createReactClass
  displayName: 'AssignDriverPopup'
  mixins: [ReactBacon.BaconMixin]
  propTypes:
    rdsOrder: PropTypes.object.isRequired
    order: PropTypes.object.isRequired

  getInitialState: ->
    visible: false
    drivers: []
    error: null
    loading: true
    geodistance: true

  componentDidMount: ->
    @plug driversStore.drivers, 'drivers'
    @plug driversStore.errors, 'error'
    @plug driversStore.loading, 'loading'
    driversStore.initRestaurant(@props.order.restaurant)

  showAssignDriverPopup: ->
    driversStore.push(@props.rdsOrder)
    @setState visible: true

  getLocale: ->
    if @state.restaurant then @state.restaurant.locale else 'en'

  onClose: ->
    @setState visible: false

  onSelect: (drv)->
    orderStore.assignDriverResult.onValue (drv)=>
      @setState visible: false
    orderStore.assignDriver(drv)

  renderError: ->
    if @state.error
      <div className="alert alert-danger" role="alert">
        There was an error trying to load data. <br/>
        {@state.error.status.code} - {@state.error.status.message}
      </div>
    else
      null

  enableDrivingDistance: ->
    @setState geodistance: false
    driversStore.calculateDriving()

  renderDrivingDistanceButton: ->
    if @state.geodistance
      label = if @state.geodistance then 'Driving' else 'Geo'
      <Button color="info" size="xsmall" onClick={@enableDrivingDistance}>{label}</Button>
    else
      null

  renderDrivers: ->
    if @state.loading
      <div>Loading available drivers...</div>
    else if @state.drivers.length == 0
      <Alert color="warning">
        <strong>Bad news!</strong> There are no online drivers!
      </Alert>
    else
      <Table striped condensed hover className="driver-selector">
        <thead>
          <tr>
            <th>Driver</th>
            <th className="text-right">Today Orders</th>
            <th className="text-right">Today Tips</th>
            <th className="text-right">Active Orders</th>
            <th className="text-right">Distance {@renderDrivingDistanceButton()}</th>
            <th>Available</th>
          </tr>
        </thead>
        <tbody>
          {
            R.map (d)=>
              <DriverBox key={d.id} driver={d} onClick={@onSelect} locale={@getLocale()}/>
            , @state.drivers
          }
        </tbody>
      </Table>

  render: ->
    o = @props.order
    rds = @props.rdsOrder
    if o.service.id == 'DELIVERY' && rds && rds.state && rds.state in ['confirmed', 'sent_to_acceptance', 'accepted', 'zuppler_notified']
      <span>
        <Button key="dispatch" color="info" onClick={@showAssignDriverPopup}><Icon name="car"/> Assign driver</Button>
        <Modal size="lg" isOpen={@state.visible} onClose={@onClose}>
          <ModalHeader>
            <ModalTitle>Available drivers to take {@props.rdsOrder.customerName} order from {@props.rdsOrder.restaurantName}</ModalTitle>
          </ModalHeader>
          <ModalBody>
            { @renderError() }
            { @renderDrivers() }
          </ModalBody>
          <ModalFooter>
            <Button color="danger" onClick={@onClose}>Close</Button>
          </ModalFooter>
        </Modal>
      </span>
    else
      null

module.exports = AssignDriverPopup
