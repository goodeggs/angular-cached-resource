app = angular.module 'cachedResource', ['ngResource']


app.factory 'cachedResource', ['$resource', '$timeout', '$q', ($resource, $timeout, $q) ->
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

      resource.$httpPromise.then (response) ->
        localStorage.setItem key, angular.toJson response

      cached = angular.fromJson localStorage.getItem key
      if cached
        if angular.isArray cached
          for item in cached
            resource.push item
        else
          angular.extend(resource, cached)

        # Resolve the promise as the cache is ready
        deferred = $q.defer()
        resource.$promise = deferred.promise
        deferred.resolve resource

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
