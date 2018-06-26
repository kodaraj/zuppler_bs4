React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'


Money = require 'components/money'
import {Card, CardBody, CardTitle, ListGroup, ListGroupItem, Label, Input} from 'reactstrap'
QuantitySelector = require './quantity'

SelectMultiple = createReactClass
  displayName: "SelectSingle"

  props:
    label: PropTypes.string.isRequired
    selections: PropTypes.arrayOf PropTypes.shape
      id: PropTypes.number.isRequired
      name: PropTypes.string.isRequired
      price: PropTypes.number
    options: PropTypes.arrayOf PropTypes.shape
      id: PropTypes.number.isRequired
      name: PropTypes.string.isRequired
      price: PropTypes.number
      image: PropTypes.object
    errors: PropTypes.arrayOf(PropTypes.string)
    onChange: PropTypes.func.isRequired
    group: PropTypes.boolean
    multi: PropTypes.boolean

  getDefaultProps: ->
    group: false
    multi: false

  onChange: (option, event) ->
    @props.onChange option, if event.target.checked then 1 else 0

  onChangeQuantity: (option, quantity, change, event) ->
    @props.onChange option, quantity + change

  selectionForOption: (option) ->
    R.find R.propEq('id', option.id), @props.selections

  render: ->
    <Card>
      <CardBody>
        <CardTitle>{@props.label}</CardTitle>
        { @props.description }
        { @renderErrors(@props.errors) }
        <ListGroup>
          { @renderOptions() }
        </ListGroup>
      </CardBody>
    </Card>

  renderOptions: ->
    if @props.group
      groups = R.values R.groupBy R.prop('group'), @props.options
      R.map @renderGroup, groups
    else
      R.map @renderGroup, [@props.options]

  renderGroup: (options) ->
    <div key={options[0].id} className="options-group">
      { @renderGroupHeader options[0] }
      { R.map @renderOption, options }
    </div>

  renderGroupHeader: (option) ->
    if @props.group
      <ListGroupItem color="info">
        {option.group_label}
      </ListGroupItem>

  renderOption: (option) ->
    onChange = R.partial @onChange, [option]
    selection = @selectionForOption(option)
    price = option.price * if selection then selection.quantity else 1
    quantity = if selection then selection.quantity else 0

    <ListGroupItem key={option.id}>
      <Label className="option-label">
        <Input type="checkbox" checked={ quantity > 0 } onChange={ onChange } />
        { ' ' }
        { option.name }
        { ' ' }
        <Money value={price} />
        { ' ' }
        { @renderMultiplier(option, selection) }
      </Label>
      { option.description }
      { @renderImage(option.image) }
    </ListGroupItem>

  renderMultiplier: (option, selection) ->
    if @props.multi and selection and selection.quantity
      <span className="pull-right">
        <QuantitySelector size='small' quantity={selection.quantity}
          adjustQuantity={R.partial @onChangeQuantity, [option, selection.quantity]} setQuantity={->} />
      </span>

  renderImage: (image) ->
    if image.active
      <img src={image.tiny} />

  renderErrors: (errors) ->
    if errors and errors.length
      <div key="errors" className="text-danger">
        { R.map @renderError, errors }
      </div>
    else
      null

  renderError: (error) ->
    <li key={error} className="error">{ error }</li>

module.exports = SelectMultiple
