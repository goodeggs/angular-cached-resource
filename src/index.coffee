app = angular.module 'cachedResource', ['ngResource']

app.service 'cacheResource', ['$resource', ($resource) ->

  return ((identity) -> identity) unless window.localStorage?

  localStorageKey = (url, parameters) ->
    for name, value of parameters
      url = url.replace ":#{name}", value
    url

  return (url) ->
    Resource = $resource.apply(null, arguments)
    CachedResource = {}

    if Resource.get?
      CachedResource.get = (parameters) ->
        parameters = null if typeof parameters is 'function'
        key = localStorageKey(url, parameters)
        console.log key

        instance = Resource.get.apply(Resource, arguments)
        instance.$promise.then (response) ->
          localStorage.setItem key, JSON.stringify response
        instance

    CachedResource

]

app
