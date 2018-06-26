React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'


menuStore = require 'zuppler-js/lib/stores/menu'
itemStore = require 'zuppler-js/lib/stores/item'

SelectSingle = require './select-single'
SelectMultiple = require './select-multiple'

Options = createReactClass
  props:
    item: PropTypes.object.isRequired
    choices: PropTypes.array.isRequired
    sizes: PropTypes.array.isRequired
    restaurant: PropTypes.array.isRequired

  mixins: [ReactBacon.BaconMixin]

  getInitialState: ->
    errors: {}
    restaurant:
      configuration:
        disable_quantity: false
    selections:
      quantity: 1
      size: null

  componentDidMount: ->
    @plug itemStore.selections, 'selections'
    @plug itemStore.errors, 'errors'

  onChangeSize: (oldSize, newSize)->
    itemStore.changeSize newSize

  onChangeModifierMultiple: (option, quantity) ->
    itemStore.updateModifierQuantity(option, quantity)

  onChangeModifierSingle: (prevOption, newOption) ->
    itemStore.updateModifierQuantity(prevOption, 0) if prevOption
    itemStore.updateModifierQuantity(newOption, 1)

  render: ->
    React.createElement("div", null,
      ( @renderSizeSelector() ),
      ( R.map @renderChoice, @props.choices )
    )

  renderSizeSelector: ->
    if @props.sizes.length > 1
      React.createElement(SelectSingle, {"id": "sizes",  \
        "key": "sizes",  \
        "label": 'Choose Size',  \
        "selected": (@state.selections.size),  \
        "options": (@props.sizes),  \
        "errors": ([]),  \
        "onChange": (@onChangeSize)})

  renderChoice: (choice) ->
    return null unless @state.selections
    filterByChoice = (choice, selections) ->
      R.filter R.propEq('choiceId', choice.id), selections.modifiers || []

    choiceErrors = (errors, choice) ->
      if errors[choice.name]
        [ errors[choice.name] ]
      else
        [ ]

    choiceModifiers = (choice) -> choice.modifiers

    if choice.multiple_selections
      React.createElement(SelectMultiple, {"id": (choice.id),  \
        "label": (choice.name),  \
        "key": "choice#{choice.id}",  \
        "description": (choice.description),  \
        "selections": (filterByChoice(choice, @state.selections)),  \
        "options": (choiceModifiers(choice)),  \
        "onChange": (@onChangeModifierMultiple),  \
        "group": (choice.allow_grouping),  \
        "multi": (choice.multiple_modifiers),  \
        "errors": (choiceErrors(@state.errors, choice))})
    else
      React.createElement(SelectSingle, {"id": (choice.id),  \
        "label": (choice.name),  \
        "key": "choice#{choice.id}",  \
        "description": (choice.description),  \
        "selected": (R.nth(0, filterByChoice(choice, @state.selections))),  \
        "options": (choiceModifiers(choice)),  \
        "onChange": (@onChangeModifierSingle),  \
        "group": (choice.allow_grouping),  \
        "errors": (choiceErrors(@state.errors, choice))})

module.exports = Options
