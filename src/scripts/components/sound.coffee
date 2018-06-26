React = require 'react'
Bacon = require 'baconjs'
ReactBacon = require 'react-bacon'
R = require 'ramda'
{Icon}= require 'react-fa'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

SoundService = createReactClass
  displayName: 'SoundService'
  mixins: [ReactBacon.BaconMixin]

  props:
    soundStream: PropTypes.object

  componentDidMount: ->
    if @props.soundStream
      @cancelNoises = @props.soundStream
        .log "Playing sound"
        .map (soundName) -> document.getElementById("noise-service-#{soundName}")
        .filter R.compose R.not, R.isNil
        .flatMap (soundElement) -> Bacon.fromPromise soundElement.play()
        .onValue -> #

  componentWillUnmount: ->
    @cancelNoises?()

  render: ->
    React.createElement("span", null)

module.exports = SoundService
