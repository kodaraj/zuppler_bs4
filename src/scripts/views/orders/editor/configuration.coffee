R = require 'ramda'
ValueEditors = require './value-editors'
Condition = require 'models/condition'

class OpType
  constructor: (@id, @label) ->

class FieldType
  constructor: (@id, @label, @opTypes, @valueType, @options) ->

class ValueType
  constructor: (@id, @editor, @options) ->

class EnumValue
  constructor: (@id, @label) ->

valueTypes =
  string: new ValueType 'string', ValueEditors.StringValueEditor
  date: new ValueType 'date', ValueEditors.DateValueEditor
  datetime: new ValueType 'datetime', ValueEditors.DateTimeValueEditor
  relative_named_date: new ValueType 'relative_named_date', ValueEditors.EnumValueEditor, [
    new EnumValue 'today', 'today'
    new EnumValue 'tomorrow', 'tomorrow'
    new EnumValue 'this_week', 'this week'
    new EnumValue 'next_week', 'next week'
    new EnumValue 'yesterday', 'yesterday'
    new EnumValue 'last_week', 'last week'
    new EnumValue 'last_week_today', 'last week today'
  ]
  relative_named_shift: new ValueType 'relative_named_shift', ValueEditors.EnumValueEditor, [
    new EnumValue 'today', 'started today'
    new EnumValue 'yesterday', 'started yesterday'
    new EnumValue '2_days_ago', 'started 2 days ago'
  ]
  relative_date: new ValueType 'relative_date', ValueEditors.RelativeDateEditor, [
    new EnumValue 'day', 'days'
    new EnumValue 'week', 'weeks'
    new EnumValue 'month', 'months'
    new EnumValue 'hour', 'hours'
  ]
  channel_lookup: new ValueType 'channel_lookup', ValueEditors.StringValueEditor
  restaurant_lookup: new ValueType 'restaurant_lookup', ValueEditors.RestaurantLookup
  state: new ValueType 'state', ValueEditors.EnumValueEditor, [
    new EnumValue 'executing', 'executing'
    new EnumValue 'missed', 'missed'
    new EnumValue 'canceled', 'canceled'
    new EnumValue 'confirmed', 'confirmed'
    new EnumValue 'invoiced', 'invoiced'
    new EnumValue 'rejected', 'rejected'
    new EnumValue 'created', 'created'
    new EnumValue 'captured', 'captured'
    new EnumValue 'accepted', 'accepted'
  ]
  tender: new ValueType 'tender', ValueEditors.EnumValueEditor, [
    new EnumValue 'CARD', 'Card'
    new EnumValue 'COD', 'Card On Delivery'
    new EnumValue 'CASH', 'Cash'
    new EnumValue 'PAYPAL', 'Paypal'
    new EnumValue 'MOLLIE', 'Mollie'
    new EnumValue 'KNet', 'KNet'
    new EnumValue 'AUTHIPAY', 'Authipay'
    new EnumValue 'BUCKID', 'Account (buckid)'
    new EnumValue 'ACCOUNT', 'Account'
    new EnumValue 'LEVELUP', 'Levelup'
    new EnumValue 'LOYALTY', 'Zupp Bucks'
    new EnumValue 'POINTS', 'Zupp Points'
    new EnumValue 'COD', 'Card on Delivery'
  ]
  order_type: new ValueType 'order_type', ValueEditors.EnumValueEditor, [
    new EnumValue 'DELIVERY', 'delivery'
    new EnumValue 'PICKUP', 'pickup'
    new EnumValue 'DINEIN', 'dinein'
    new EnumValue 'CURBSIDE', 'curbside'
  ]
  card_type: new ValueType 'card_type', ValueEditors.EnumValueEditor, [
    new EnumValue 'visa', 'Visa'
    new EnumValue 'master', 'Master'
    new EnumValue 'american_express', 'American Express'
    new EnumValue 'discover', 'Discover'
  ]
  driver_lookup: new ValueType 'driver_lookup', ValueEditors.DriverLookup
  delivery_state: new ValueType 'delivery_state', ValueEditors.EnumValueEditor, [
    new EnumValue 'confirmed', 'pending driver assigment'
    new EnumValue 'sent_to_acceptance', 'pending driver acceptance'
    new EnumValue 'accepted', 'accepted'
    new EnumValue 'zuppler_notified', 'delivering'
    new EnumValue 'delivered', 'delivered'
    new EnumValue 'delivery_canceled', 'delivery canceled'
  ]
  delivery_service_lookup: new ValueType 'delivery_service_lookup', ValueEditors.DeliveryServiceLookup

opTypes =
  string:
    'contain': new OpType('contain'  , 'contains')
    '!contain': new OpType('!contain' , 'does not contain')
    'equal': new OpType('equal', 'is equal to')
    'prefix': new OpType('prefix'  , 'begins with')
  string_non_indexed:
    'equal': new OpType('equal', 'is')
    '!equal': new OpType('!equal' , 'is not')
  date:
    '~=': new OpType('~=', 'is') # today, tomorrow, this week, next week, last week
    '~<>': new OpType('~<>', 'is in ') # 3 days
    'within': new OpType('within', 'is within')
    'within past': new OpType('within past', 'is in last')
    'gt': new OpType('gt', 'is after ') # 3 days
    'lt': new OpType('lt', 'is before ') # 3 days
    'between': new OpType('between' , 'is between')
    '!between': new OpType('!between' , 'is not between')
    'in': new OpType('in', 'is between time')
    '!in': new OpType('!in', 'is not between time')
    's~=': new OpType('s~=', 'on shift that') # today, yesterday, 2 days ago
  enum:
    'equal': new OpType('equal' , 'is')
    '!equal': new OpType('!equal' , 'is not')

dateValueTypeByOpId = (opId) ->
  switch opId
    when 'between', '!between' then valueTypes.date
    when 'in', '!in' then valueTypes.datetime
    when '~=' then valueTypes.relative_named_date
    when 's~=' then valueTypes.relative_named_shift
    when '~<>', 'gt', 'lt', 'within', 'within past' then valueTypes.relative_date

restaurantValueTypeByOpId = (opId) ->
  switch opId
    when 'equal' then valueTypes.restaurant_lookup
    else valueTypes.string

driverValueTypeByOpId = (opId) ->
  switch opId
    when 'equal' then valueTypes.driver_lookup
    else valueTypes.string

fieldTypes =
  state: new FieldType('state', 'Order State', opTypes.enum, valueTypes.state)
  customer_name: new FieldType('customer_name', 'Customer Name', opTypes.string, valueTypes.string)
  customer_email: new FieldType('customer_email', 'Customer Email', opTypes.string, valueTypes.string)
  customer_phone: new FieldType('customer_phone', 'Customer Phone', opTypes.string, valueTypes.string)
  delivery_address: new FieldType('delivery_address', 'Delivery Address', opTypes.string, valueTypes.string)
  uuid: new FieldType('uuid', 'Order ID', opTypes.string, valueTypes.string)
  code: new FieldType('code', 'Conf. Code', opTypes.string, valueTypes.string)
  service_id: new FieldType('service_id', 'Order Type', opTypes.enum, valueTypes.order_type)
  restaurant_name: new FieldType('restaurant_name', 'Restaurant', opTypes.string, restaurantValueTypeByOpId)
  time: new FieldType('time', 'Order date', opTypes.date, dateValueTypeByOpId)
  created_at: new FieldType('created_at', 'Order placed', opTypes.date, dateValueTypeByOpId)
  updated_at: new FieldType('updated_at', 'Order changed', opTypes.date, dateValueTypeByOpId)
  channel_name: new FieldType('channel_name', 'Channel', opTypes.string, valueTypes.string)
  tender_id: new FieldType('tender_id', 'Payment Type', opTypes.enum, valueTypes.tender)
  card_type: new FieldType('card_type', 'Card Type', opTypes.enum, valueTypes.card_type)
  card_number: new FieldType('card_number', 'Card last 4 digits', opTypes.string_non_indexed, valueTypes.string)

additionFieldTypes =
  dispatcher:
    'rds.driver_id': new FieldType('rds.driver_id', 'Driver', opTypes.string_non_indexed, driverValueTypeByOpId)
    'rds.state': new FieldType('rds.state', 'Delivery State', opTypes.enum, valueTypes.delivery_state)
    'rds.delivery_service': new FieldType('rds.delivery_service', 'Delivery Service', opTypes.enum, valueTypes.delivery_service_lookup)

fieldTypesForRoles = (roles)->
  R.merge fieldTypes, R.mergeAll(R.values(R.pick(roles, additionFieldTypes)))

fieldTypeById = (id) ->
  fieldTypes[id] || R.mergeAll(R.values(additionFieldTypes))[id]

opTypeById = (fieldTypeId, id) ->
  field = fieldTypeById(fieldTypeId)
  if id then field.opTypes[id] else R.values(field.opTypes)[0]

valueTypeById = (fieldTypeId, opTypeId) ->
  valueType = fieldTypeById(fieldTypeId).valueType
  if typeof valueType is 'function' then valueType(opTypeId) else valueType

firstOpId = (fieldTypeId) ->
  R.values(fieldTypeById(fieldTypeId).opTypes)[0].id

defaultValue = (fieldTypeId, opTypeId) ->
  fieldType = fieldTypeById fieldTypeId
  opType = opTypeById fieldTypeId
  valueType = valueTypeById fieldTypeId, opTypeId

  switch valueType.id
    when 'string', 'restaurant_lookup', 'channel_lookup', 'driver_lookup' then ''
    when 'relative_date' then {count: 1, unit: valueType.options[0].id}
    when 'date' then ValueEditors.defaultDateInterval()
    else
      valueType.options[0].id if valueType.options and valueType.options.length

module.exports =
  fieldTypeById: fieldTypeById
  opTypeById: opTypeById
  valueTypeById: valueTypeById
  firstOpId: firstOpId
  defaultValue: defaultValue
  fieldTypes: fieldTypes
  fieldTypesForRoles: fieldTypesForRoles
  opTypes: opTypes
  valueTypes: valueTypes
