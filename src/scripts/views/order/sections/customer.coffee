React = require 'react'
ReactBacon = require 'react-bacon'
R = require 'ramda'
moment = require 'moment'
{Icon }= require 'react-fa'
hopUtil = require 'utils/hop'
numeral = require 'utils/numeral_setup'
createReactClass = require 'create-react-class'

{ BaconMixin } = ReactBacon

orderUtils = require '../components/utils'
{ toID, shortID, touple, booleanOf, currency, percent } = orderUtils
{ formatTimeWithOffset, pairsToTable, pairsToList, googleMapsLinkToAddress } = orderUtils


CustomerInfo = createReactClass
  displayName: 'CustomerInfo'

  render: ->
    o = @props.order
    pairs = []
    pairs = R.concat pairs, touple 'Name', o.customer.name
    pairs = R.concat pairs, touple 'Email', React.createElement("a", {"href": "email:#{o.customer.email}"}, (o.customer.email)) if o.customer.email
    pairs = R.concat pairs, touple 'Phone', React.createElement("a", {"href": "tel:#{o.customer.phone}"}, (o.customer.phone)) if o.customer.phone
    pairs = R.concat pairs, touple 'Catering', booleanOf o.settings.catering
    pairs = R.concat pairs, touple "Registered", booleanOf !!o.customer.resource_url

    pairs = R.reduce (accum, group) ->
      R.concat accum, touple group.group_name, "" unless group.group_name is "_none_"
      R.reduce (accum, data) ->
        R.concat accum, touple data.name || "Info", data.value || ""
      , accum, group.data
    , pairs, o.settings.extra_fields

    pairsToList "customer_info", pairs, header: React.createElement("span", null, "Customer")

module.exports = CustomerInfo
