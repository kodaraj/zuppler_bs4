Bacon = require 'baconjs'
R = require 'ramda'
request = require 'utils/request'

intervalGenerator = Bacon.interval(60*1000)

toJSON = (data) -> data.json()

currentVersion = "#{VERSION}"

console.log "Current App Version is", currentVersion

loadVersion = (url) ->
  Bacon
    .fromPromise(request.wrapRequest fetch(url).then(toJSON))
    .map R.path(['version', 'version'])

latestVersion = Bacon
  .once("/version.json")
  .sampledBy intervalGenerator
  .flatMap loadVersion

if typeof window.fetch == "function"
  module.exports = Bacon
    .combineTemplate current: Bacon.constant(currentVersion), latest: latestVersion
    .filter ({current, latest}) -> current != latest
    .skipDuplicates(R.equals)
else
  # console.log("Warning version checking is unavailable")
  module.exports = Bacon.never()
