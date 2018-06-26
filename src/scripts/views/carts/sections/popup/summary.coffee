React = require 'react'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

Money = require 'components/money'

module.exports = createReactClass
  displayName: "SelectionsSummary"

  props:
    selectionsInfo: PropTypes.object.isRequired

  render: ->
    if R.keys(@props.selectionsInfo).length > 0
      React.createElement("div", null, ( R.map @renderChoiceSelections, R.toPairs @props.selectionsInfo ))
    else
      null

  renderChoiceSelections: ([modifierName, options]) ->
    React.createElement("p", {"key": (modifierName)},
      React.createElement("strong", null, (modifierName), ": "),
      ( R.intersperse @renderSeparator(), R.map @renderChoiceSelectionsOption, options )
    )

  renderChoiceSelectionsOption: ({id, name, quantity, price}) ->
    React.createElement("span", {"key": (id)},
      (@renderQuantityPrefix(quantity)),
      React.createElement("span", {"key": "n"}, (name), " "),
      React.createElement(Money, {"value": (price)})
    )

  renderSeparator: ->
    React.createElement("span", null, ", ")

  renderQuantityPrefix: (quantity) ->
    "#{quantity} x " if quantity > 1
