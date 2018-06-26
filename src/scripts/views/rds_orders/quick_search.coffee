React = require 'react'
{ Icon } = require 'react-fa'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'
{ withRouter } = require 'react-router-dom'
listStore = require 'stores/lists'
uiStore = require 'stores/ui'
List = require 'models/list'
Condition = require 'models/condition'
NavigationMixin = require 'components/lib/navigation'
{ Form, FormGroup, Label, Input, Button } = require 'reactstrap'

QuickSearch = createReactClass
  displayName: 'QuickSearch'
  mixins: [NavigationMixin]

  onQuickSearch: (event) ->
    event.preventDefault()
    value = @refs.quickSearchInput.getValue()
    if value and value.length > 0
      @refs.quickSearchInput.getInputDOMNode().value = ""
      list = listStore.addListFromQuickSearch value
      @props.history.push "/rds/#{list.id}"
    else
      alert "Please enter something to search for!"

  render: ->
    <Form className="form-inline" role="form" onSubmit={@onQuickSearch}>
      <FormGroup>
        <Label className="sr-only">Find orders</Label>
        <Input type="text" ref="quickSearchInput" placeholder="Find orders" />
      </FormGroup>
      <Button onClick={@onQuickSearch}>
        <Icon name="search" />
      </Button>
      {@props.children}
    </Form>

module.exports = withRouter(QuickSearch)
