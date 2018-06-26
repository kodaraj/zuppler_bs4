React = require 'react'
R = require 'ramda'
createReactClass = require 'create-react-class'

{ Icon }= require 'react-fa'
PropTypes = require 'prop-types'

import {Form, FormGroup, Button, Input} from 'reactstrap'

module.exports = createReactClass
  props:
    quantity: PropTypes.number.isRequired
    adjustQuantity: PropTypes.func.isRequired
    setQuantity: PropTypes.func.isRequired
    size: PropTypes.oneOf ['large', 'small']

  getDefaultProps: ->
    size: 'large'

  setQuantity: (event) ->
    validator = R.compose R.max(1), R.min(1000), R.defaultTo(1)
    @props.setQuantity validator parseInt event.target.value

  render: ->
    <Form inline>
      <Button onClick={R.partial @props.adjustQuantity, [-1]} size="xsmall">
        <Icon name="minus" />
      </Button>
      <FormGroup controlId="quantity" size="small">
        <Input type="number" placeholder="1" value={@props.quantity} onChange={@setQuantity} style={width: "60px"}/>
      </FormGroup>
      <Button onClick={R.partial @props.adjustQuantity, [1]} size="xsmall">
        <Icon name="plus" />
      </Button>
    </Form>
