app = angular.module 'cachedResource', ['ngResource']

localStorageKey = (url, parameters) ->
  for name, value of parameters
    url = url.replace ":#{name}", value
  url

simpleCache = (Resource, method, url) ->
  (parameters) ->
    parameters = null if angular.isFunction parameters
    key = localStorageKey(url, parameters)
    resource = Resource[method].apply(Resource, arguments)

    resource.$promise.then (response) ->
      localStorage.setItem key, angular.toJson response

    cached = angular.fromJson localStorage.getItem key
    if angular.isArray cached
      for item in cached
        resource.push item
      resource
    else
      angular.extend(resource, cached)


app.service 'cacheResource', ['$resource', ($resource) ->

  return $resource unless window.localStorage?

  return (url) ->
    Resource = $resource.apply(null, arguments)
    CachedResource = {}

    for method in ['get', 'query']
      if Resource[method]?
        CachedResource[method] = simpleCache Resource, method, url

    CachedResource

]

app
