React = require 'react'
ReactDOM = require 'react-dom'
{ Icon }= require 'react-fa'
R = require 'ramda'
PropTypes = require 'prop-types'
createReactClass = require 'create-react-class'

listStore = require 'stores/lists'
uiStore = require 'stores/ui'
List = require 'models/list'
Condition = require 'models/condition'
NavigationMixin = require 'components/lib/navigation'
{ InputGroup, InputGroupAddon, Input, FormGroup, Button , Form, Navbar, Nav} = require 'reactstrap'

QuickSearch = createReactClass
  displayName: 'QuickSearch'
  mixins: [NavigationMixin]

  onQuickSearch: (event) ->
    event.preventDefault()
    qsInput = ReactDOM.findDOMNode(@refs.quickSearchInput)
    value = qsInput.value
    if value and value.length > 0
      list = listStore.addListFromQuickSearch value
      @props.history.push "/lists/#{list.id}"
      qsInput.value = ""
    else
      alert "Please enter something to search for!"

  render: ->
    <Nav className="ml-auto" navbar>
      <Form onSubmit={@onQuickSearch} className = "form-inline">
        <FormGroup>
          <InputGroup>
            <Input type="text" ref="quickSearchInput" placeholder="Find orders" />
            <InputGroupAddon addonType="append">
              <Button type="submit"><Icon name="search"></Icon></Button>
            </InputGroupAddon>
          </InputGroup>
        </FormGroup>
      </Form>
    </Nav>

{ withRouter } = require 'react-router-dom'
module.exports = withRouter(QuickSearch)
