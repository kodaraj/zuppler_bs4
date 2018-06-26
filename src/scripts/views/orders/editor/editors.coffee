React = require 'react'
R = require 'ramda'
leUtils = require './utils'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
{ Input } = require 'reactstrap'

FieldTypeEditor = createReactClass
  displayName: 'FieldTypeEditor'
  propTypes:
    fieldTypes: PropTypes.array.isRequired
    onChange: PropTypes.func.isRequired
    condition: PropTypes.object.isRequired

  onChange: (event) ->
    @props.onChange event.target.value

  render: ->
    { condition, onChange } = @props
    fieldTypesMarkup = R.values(@props.fieldTypes).map leUtils.typeToMarkup
    <Input type="select" value={condition.field} onChange={@onChange}>
      {fieldTypesMarkup}
    </Input>

OpTypeEditor = createReactClass
  displayName: 'OpTypeEditor'
  propTypes:
    onChange: PropTypes.func.isRequired
    fieldType: PropTypes.object.isRequired

  onChange: (event) ->
    @props.onChange event.target.value

  render: ->
    opTypesMarkup = R.values(@props.fieldType.opTypes).map leUtils.typeToMarkup
    <Input type="select" value={@props.condition.op} onChange={@onChange}>
      {opTypesMarkup}
    </Input>

module.exports =
  FieldTypeEditor: FieldTypeEditor
  OpTypeEditor: OpTypeEditor
