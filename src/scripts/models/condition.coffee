R = require 'ramda'
uuid = require 'uuid'
moment = require 'moment'

class Condition
	constructor: (@field, @op, @value = '') ->
		@id = uuid()

module.exports = Condition
