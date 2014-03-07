app = angular.module 'cachedResource', ['ngResource']

app.service 'cacheResource', ['$resource', '$timeout', '$q', ($resource, $timeout, $q) ->

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
        instance = Resource.get.apply(Resource, arguments)

        instance.$promise.then (response) ->
          localStorage.setItem key, angular.toJson response

        angular.extend(instance, angular.fromJson localStorage.getItem key)

    CachedResource

]

app
