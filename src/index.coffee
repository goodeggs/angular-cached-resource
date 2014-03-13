app = angular.module 'cachedResource', ['ngResource']

app.factory 'cachedResource', ['$resource', '$timeout', '$q', ($resource, $timeout, $q) ->
  localStorageKey = (resourceKey, parameters) ->
    instanceKey = ("#{name}=#{value}" for name, value of parameters).join('&')
    "cachedResource://#{resourceKey}?#{instanceKey}"

  readCache = (action, resourceKey) ->
    (parameters) ->
      resource = action.apply(null, arguments)
      resource.$httpPromise = resource.$promise
      return resource unless window.localStorage?

      parameters = null if angular.isFunction parameters
      key = localStorageKey(resourceKey, parameters)

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

  writeCache = (action, resourceKey) ->
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
    # ...but adding an additional cacheKey param in the beginning, so we have:
    #
    # cachedResource(cacheKey, url, [paramDefaults], [actions])
    args = Array::slice.call arguments
    resourceKey = args.shift()
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

    for name, params of actions
      action = Resource[name].bind(Resource)
      if params.method is 'GET'
        CachedResource[name] = readCache(action, resourceKey)
      else if params.method in ['POST', 'PUT', 'DELETE']
        CachedResource[name] = writeCache(action, resourceKey)
      else
        CachedResource[name] = action

    CachedResource
]

app
