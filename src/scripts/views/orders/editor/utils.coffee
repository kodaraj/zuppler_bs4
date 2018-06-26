React = require 'react'
List = require 'models/list'
Condition = require 'models/condition'
config = require './configuration'
{ addId } = require 'utils/resources'

defaultCondition = ->
  field = config.fieldTypes.uuid
  addId new Condition field.id, config.firstOpId(field.id)

defaultList =  ->
  new List
    name: 'New Search'
    appliesTo: 'any'
    conditions: [ defaultCondition() ]

typeToMarkup = (t) ->
  React.createElement("option", {"key": (t.id), "value": (t.id)}, (t.label))

module.exports =
  typeToMarkup: typeToMarkup
  defaultCondition: defaultCondition
  defaultList: defaultList
