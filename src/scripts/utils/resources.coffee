R = require 'ramda'
uuid = require 'uuid'

findResourceLink = (data, resourceName, method) ->
  link = R.find (resource) ->
    resource.name is resourceName and R.contains method, resource.methods
  , data.links
  if link
    link.url

resourceLink = R.curry (name, method, url) ->
  name: name
  methods: [method]
  url: url

notSelf = (link) ->
  link.name != 'self'

withDefaultTrue = R.defaultTo(true)

onlyInteractive = (link) ->
  withDefaultTrue(link.interactive)

addId = (o) ->
  R.assoc 'id', uuid(), o

module.exports =
  findResourceLink: findResourceLink
  resourceLink: resourceLink
  notSelf: notSelf
  onlyInteractive: onlyInteractive
  addId: addId
