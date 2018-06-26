Bacon = require 'baconjs'
R = require 'ramda'
portalStore = require 'zuppler-js/lib/stores/portal'

CHANNEL_URL = "#{API3_SVC}/v3/channels/zuppler.json"

portalStore.initChannelFromURL CHANNEL_URL
