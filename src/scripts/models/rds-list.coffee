List = require './list'

class RdsList extends List
  @MODEL_VERSION: 1
  constructor: (payload) ->
    super payload
    @_version ||= RdsList.MODEL_VERSION
    @type = 'rds'

module.exports = RdsList
