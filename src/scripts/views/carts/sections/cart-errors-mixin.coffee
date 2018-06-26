R = require 'ramda'
Bacon = require 'baconjs'
React = require 'react'
cx = require 'classnames'
{ Icon }= require 'react-fa'

import { Card, CardBody, CardTitle , ListGroup} from 'reactstrap';
cartStore = require 'zuppler-js/lib/stores/cart'
cartSettingsStore = require 'zuppler-js/lib/stores/cart/settings'

# takes an object with all cart messages centralized and returns the count of them
countErrors = R.pipe R.values, R.map(R.pipe(R.prop('errors'), R.length)), R.sum
extractCartMessages = R.curry (kind, errors, section) ->
  R.compose(R.prop(kind), R.defaultTo({errors: [], info: []}), R.prop(section))(errors)
extractErrors = extractCartMessages('errors')
extractInfos = extractCartMessages('info')

kindToClass = (kind) ->
  switch kind
    when 'error' then 'danger'
    when 'info' then 'info'

renderMessage = R.curry (kind, msg) ->
  <div className={"text-" + kindToClass(kind)}>{msg}</div>

renderError = renderMessage 'error'
renderInfo = renderMessage 'info'

renderMessageGroupItem = R.curry (kind, sectionName, msg) ->
  if msg then <ListGroupItem bsStyle={kindToClass(kind)}>{sectionName}: {msg}</ListGroupItem>

renderErrorGroupItem = renderMessageGroupItem('error')
renderInfoGroupItem = renderMessageGroupItem('info')

module.exports =
  getInitialState: ->
    cartMessages: {}

  # Builds a stream of merged errors from all cart sections as section: [errors], [info]
  componentDidMount: ->
    errorKeys = [ 'cart' ]

    errorStreams = [
      cartStore.errors,
      ]

    errorStream = ([key, stream]) ->
      Bacon
        .constant(key)
        .flatMap stream
        .map (data) -> R.assoc key, data, {}

    stream = Bacon
      .mergeAll R.map errorStream, R.zip errorKeys, errorStreams
      .scan {}, R.merge

    @plug stream, 'cartMessages'

  cartValidationState: (field) ->
    errors = R.defaultTo [], R.path [field, 'errors'], @state.errors
    infos = R.defaultTo [], R.path [field, 'info'], @state.errors
    if errors.length > 0
      'error'
    else if infos.length > 0
      'warning'
    else
      'success'

  renderFieldMessages: (field) ->
    errors = R.defaultTo [], R.path([field, 'errors'], @state.errors)
    info = R.defaultTo [], R.path([field, 'info'], @state.errors)

    if errors.length + info.length
      R.flatten [ R.map(renderError, errors), R.map(renderInfo, info) ]

  renderCartMessages: ->
    messages = @state.cartMessages || {}
    return null if !countErrors(messages)
    errorsFor = extractErrors(messages)
    infoFor = extractInfos(messages)

    <Card color="warning">
      <CardBody>
        <CardTitle>Other problems with the order</CardTitle>
        <ListGroup>
          { R.map renderErrorGroupItem("Cart"),       errorsFor('cart') }
          { R.map  renderInfoGroupItem("Cart"),       infoFor('cart') }
        </ListGroup>
      </CardBody>
    </Card>


  cartErrorCount: ->
    countErrors @state.cartMessages || {}
