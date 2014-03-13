app = angular.module 'cachedResource', ['ngResource']

app.factory 'cachedResource', ['$resource', '$timeout', '$q', ($resource, $timeout, $q) ->
  LOCAL_STORAGE_PREFIX = 'cachedResource://'

  cache = if window.localStorage?
    getItem: (key, fallback) ->
      item = localStorage.getItem("#{LOCAL_STORAGE_PREFIX}#{key}")
      if item? then angular.fromJson(item) else fallback
    setItem: (key, value) ->
      localStorage.setItem("#{LOCAL_STORAGE_PREFIX}#{key}", angular.toJson value)
      value
  else
    getItem: (key, fallback) -> fallback
    setItem: (key, value) -> value

  readKey = (resourceKey, parameters) ->
    key = resourceKey
    paramKeys = Object.keys(parameters).sort()
    if paramKeys.length
      key += '?' + ("#{param}=#{parameters[param]}" for param in paramKeys).join('&')
    key

  readCache = (action, resourceKey) ->
    (parameters) ->
      resource = action.apply(null, arguments)
      resource.$httpPromise = resource.$promise

      parameters = null if angular.isFunction parameters
      key = readKey(resourceKey, parameters)

      resource.$httpPromise.then (response) ->
        cache.setItem key, response

      cached = cache.getItem key
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

  writeCache = (action, resourceKey) ->
    (parameters) ->
      writeArgs = arguments
      resource = action.apply(null, writeArgs)
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
    # ...but adding an additional cacheKey param in the beginning, so we have:
    #
    # cachedResource(resourceKey, url, [paramDefaults], [actions])
    args = Array::slice.call arguments
    $key = args.shift()
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
    CachedResource =
      $resource: Resource
      $key: $key

    for name, params of actions
      action = Resource[name].bind(Resource)
      if params.method is 'GET'
        CachedResource[name] = readCache(action, $key)
      else if params.method in ['POST', 'PUT', 'DELETE']
        CachedResource[name] = writeCache(action, $key)
      else
        CachedResource[name] = action

    CachedResource
]

app
