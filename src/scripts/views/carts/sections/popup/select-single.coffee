React = require 'react'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

Money = require 'components/money'
import {Label, Input, ListGroup, ListGroupItem, Card, CardBody, CardTitle} from 'reactstrap'
SelectSingle = createReactClass
  displayName: "SelectSingle"

  props:
    label: PropTypes.string.isRequired
    selected: PropTypes.object
    options: PropTypes.arrayOf PropTypes.shape
      id: PropTypes.number.isRequired
      name: PropTypes.string.isRequired
      price: PropTypes.number
    errors: PropTypes.arrayOf(PropTypes.string)
    onChange: PropTypes.func.isRequired
    group: PropTypes.boolean

  getDefaultProps: ->
    group: false
    selected:
      id: null

  onChange: (option) ->
    if option != @props.selected
      @props.onChange @props.selected, option

  render: ->
    <Card>
      <CardBody>
        <CardTitle>
          {@props.label}
        </CardTitle>
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
    <div key={options[0].group} className="options-group">
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
    selected = @props.selected || id: null
    <ListGroupItem key={option.id}>
      <Label className="option-label">
        <Input type="radio" checked={ R.eqProps('id', option, selected) } onChange={ onChange } />
        { ' ' }
        { option.name }
        {' '}
        <Money value={option.price} />
      </Label>
      { option.description }
      { @renderImage(option.image) }
    </ListGroupItem>

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
    <div className="choice-error" key={error} className="error">
      { error }
    </div>

module.exports = SelectSingle
