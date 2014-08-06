resourceManagerListener = null
debugMode = off

module?.exports = app = angular.module 'ngCachedResource', ['ngResource']
app.provider '$cachedResource', class $cachedResourceProvider
  constructor: ->
    @$get = $cachedResourceFactory
  setDebugMode: (newSetting = on) ->
    debugMode = newSetting

$cachedResourceFactory = ['$resource', '$timeout', '$q', '$log', ($resource, $timeout, $q, $log) ->

  bindLogFunction = (logFunction) ->
    (message...) ->
      message.unshift 'ngCachedResource'
      $log[logFunction].apply($log, message)

  log =
    debug: if debugMode then bindLogFunction('debug') else (->)
    error: bindLogFunction 'error'

  CachedResourceManager = require('./cached_resource_manager')(log)
  resourceManager = new CachedResourceManager($resource, $timeout, $q)

  document.removeEventListener 'online', resourceManagerListener if resourceManagerListener
  resourceManagerListener = (event) -> resourceManager.flushQueues()
  document.addEventListener 'online', resourceManagerListener

  $cachedResource = ->
    resourceManager.add.apply resourceManager, arguments
  for fn in ['clearAll', 'clearUndefined']
    $cachedResource[fn] = angular.bind resourceManager, resourceManager[fn]
  return $cachedResource

]
