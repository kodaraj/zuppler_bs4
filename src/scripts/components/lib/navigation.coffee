NavigationMixin =
  transitionTo: (url)->
    localStorage.setItem 'previousUrl', window.location.hash
    console.log "Navigating to #{url}"
    window.location.hash = url

  goBack: ->
    #TODO - find a better solution for back navigation
    window.location.hash = localStorage.getItem('previousUrl') || window.location.hash
    # @context.router.history.goBack()

module.exports = NavigationMixin
