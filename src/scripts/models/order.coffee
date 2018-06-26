Bacon = require 'baconjs'
R = require 'ramda'

orderStore = require 'stores/order'

class Order
  @MODEL_VERSION: 1
  constructor: (payload) ->
    @type     = 'orders'
    { @id, @name, @temporary, @_version } = payload
    @name ||= "##{@id.split('-')[0]}"
    @_version ||= Order.MODEL_VERSION
    @loading  = Bacon.never()

  toExternalForm: ->
    R.pick ['id', 'type', 'name', '_version' ], @

module.exports = Order
