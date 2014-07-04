resourceManagerListener = null
debugMode = off

module?.exports = app = angular.module 'ngCachedResource', ['ngResource']
app.provider '$cachedResource', class $cachedResourceProvider
  constructor: ->
    @$get = $cachedResourceFactory
  setDebugMode: (newSetting = on) ->
    debugMode = newSetting

$cachedResourceFactory = ['$resource', '$timeout', '$q', '$log', ($resource, $timeout, $q, $log) ->

  log =
    debug: if debugMode then angular.bind($log, $log.debug, 'ngCachedResource') else (->)
    error: angular.bind($log, $log.error, 'ngCachedResource')

  CachedResourceManager = require('./cached_resource_manager')(log)
  resourceManager = new CachedResourceManager($resource, $timeout, $q)

  document.removeEventListener 'online', resourceManagerListener if resourceManagerListener
  resourceManagerListener = (event) -> resourceManager.flushQueues()
  document.addEventListener 'online', resourceManagerListener

  $cachedResource = ->
    resourceManager.add.apply resourceManager, arguments
  for fn in ['clearCache', 'clearUndefined']
    $cachedResource[fn] = angular.bind resourceManager, resourceManager[fn]
  return $cachedResource

]
