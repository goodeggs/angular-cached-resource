app = angular.module 'cachedResource', ['ngResource']


app.factory 'cacheResource', ['$resource', '$timeout', '$q', ($resource, $timeout, $q) ->
  localStorageKey = (url, parameters) ->
    for name, value of parameters
      url = url.replace ":#{name}", value
    url

  simpleCache = (Resource, method, url) ->
    (parameters) ->
      resource = Resource[method].apply(Resource, arguments)
      resource.$httpPromise = resource.$promise
      return resource unless window.localStorage?

      parameters = null if angular.isFunction parameters
      key = localStorageKey(url, parameters)

      deferred = $q.defer()
      resource.$promise = deferred.promise

      resourcePromise.then (response) ->
        localStorage.setItem key, angular.toJson response

      cached = angular.fromJson localStorage.getItem key
      if cached
        if angular.isArray cached
          for item in cached
            resource.push item
        else
          angular.extend(resource, cached)

        # Notify the cached item is available on next tick
        $timeout ->
          deferred.notify 'cacheReady'

      resource

  return (url) ->
    Resource = $resource.apply(null, arguments)
    CachedResource = {}

    for method in ['get', 'query']
      if Resource[method]?
        CachedResource[method] = simpleCache Resource, method, url

    CachedResource

]

app
