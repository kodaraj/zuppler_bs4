R = require 'ramda'
React = require 'react'
ReactBacon = require 'react-bacon'
cx = require 'classnames'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
RS = require 'reactstrap'

import { CardBody, CardHeader, ListGroup, ListGroupItem} from 'reactstrap'

Card = createReactClass
  displayName: 'ChannelCard'

  mixins: [ReactBacon.BaconMixin]

  props:
    cart: PropTypes.object.isRequired
    onChangeSection: PropTypes.func

  getInitialState: ->
    channel:
      name: "Loading..."
    availableChannels: []

  componentDidMount: ->
    @plug @props.cart.channel, 'channel'
    @plug @props.cart.availableChannels, 'availableChannels'

  render: ->
    noop = ->
    active = !!@state.channel
    className = cx "panel-success": active, "panel-info": !active
    onClick = if active then R.partial @props.onChangeSection, ['channel'] else noop
    channelName = @state.channel.name || "Click to select"

    <RS.Card onClick={onClick} className={className} tag={@props.cart.id}>
      <CardHeader>
        {@renderHeader()}
      </CardHeader>
      <CardBody>
          <span key="name"><strong>{ channelName }</strong></span>
      </CardBody>
    </RS.Card>

  renderHeader: ->
    <div>On channel:</div>

Editor = createReactClass
  displayName: 'ChannelEditor'

  mixins: [ReactBacon.BaconMixin]

  props:
    cart: PropTypes.object.isRequired
    onClose: PropTypes.func.isRequired

  getInitialState: ->
    availableChannels: []
    current: null

  componentDidMount: ->
    @plug @props.cart.availableChannels, 'availableChannels'
    @plug @props.cart.channel, 'current'

  onChangeChannel: (channel) ->
    @props.cart.setChannel channel
    @props.onClose('user')

  render: ->
    <div>
      <h5>Select channel on which the order will be placed:</h5>
      <ListGroup>
        { R.map @renderChannelOption, @state.availableChannels }
      </ListGroup>
    </div>

  renderChannelOption: (channel) ->
    <ListGroupItem key={channel.name} onClick={R.partial @onChangeChannel, [channel]}
      active={channel == @state.current}>
      { channel.name } { channel.url }
    </ListGroupItem>

module.exports =
  name: 'channel'
  Card: Card
  Editor: Editor
