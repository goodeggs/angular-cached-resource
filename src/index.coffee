app = angular.module 'cachedResource', ['ngResource']

app.factory 'cachedResource', ['$resource', '$timeout', '$q', ($resource, $timeout, $q) ->
  localStorageKey = (url, parameters) ->
    for name, value of parameters
      url = url.replace ":#{name}", value
    url

  readCache = (action, url) ->
    (parameters) ->
      resource = action.apply(null, arguments)
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

  writeCache = (action, url) ->
    (parameters) ->
      writeArgs = arguments
      resource = action.apply(null, writeArgs)
      return resource unless window.localStorage?
      resource

  defaultActions =
    get:    { method: 'GET',    }
    query:  { method: 'GET',    isArray: yes }
    save:   { method: 'POST',   }
    remove: { method: 'DELETE', }
    delete: { method: 'DELETE', }

  return ->
    # we are mimicking the API of $resource, which is:
    # $resource(url, [paramDefaults], [actions])
    args = Array::slice.call arguments
    url = args.shift()
    while args.length
      arg = args.pop()
      if typeof arg[Object.keys(arg)[0]] is 'object'
        actions = arg
      else
        paramDefaults = arg
    actions ?= defaultActions
    paramDefaults ?= {}

    Resource = $resource.call(null, url, paramDefaults, actions)
    CachedResource = {}

    for name, action of actions
      if action.method is 'GET'
        CachedResource[name] = readCache Resource[name].bind(Resource), url
      else if action.method in ['POST', 'PUT', 'DELETE']
        CachedResource[name] = writeCache Resource[name].bind(Resource), url
      else
        CachedResource[name] = Resource[name]

    CachedResource
]

app
