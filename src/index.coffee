app = angular.module 'cachedResource', []

app.service 'cacheResource', ->

  return ((identity) -> identity) unless window.localStorage?

  localStorageKey = (Resource, parameters) ->
    console.log {Resource, parameters}
    'key'

  (Resource) ->
    CachedResource = {}

    if Resource.get?
      CachedResource.get = (parameters) ->
        parameters = null if typeof parameters is 'function'
        key = localStorageKey(Resource, parameters)

        instance = Resource.get.apply(Resource, arguments)
        instance.$promise.then (response) ->
          # localStorage.setItem key, response
        instance

    CachedResource

app
