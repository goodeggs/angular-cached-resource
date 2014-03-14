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

  class ResourceCacheEntry
    constructor: (resourceKey, params) ->
      @key = resourceKey
      paramKeys = Object.keys(params).sort()
      if paramKeys.length
        @key += '?' + ("#{param}=#{params[param]}" for param in paramKeys).join('&')
      {@value, @dirty} = cache.getItem(@key, {})
    set: (@value) ->
      @dirty = yes
      @_update()
    clean: ->
      @dirty = no
      @_update()
    _update: ->
      cache.setItem @key, {@value, @dirty}

  cachedResources = []

  readCache = (action, resourceKey) ->
    (parameters) ->
      resource = action.apply(null, arguments)
      resource.$httpPromise = resource.$promise

      parameters = null if angular.isFunction parameters
      cacheEntry = new ResourceCacheEntry(resourceKey, parameters)

      resource.$httpPromise.then (response) ->
        cacheEntry.set response

      if cacheEntry.value
        if angular.isArray(cacheEntry.value)
          for item in cacheEntry.value
            resource.push item
        else
          angular.extend(resource, cacheEntry.value)

        # Resolve the promise as the cache is ready
        deferred = $q.defer()
        resource.$promise = deferred.promise
        deferred.resolve resource

      resource

  writeCache = (action, resourceKey) ->
    ->
      # according to the ngResource documentation:
      # Resource.action([parameters], postData, [success], [error])
      args = Array::slice.call arguments
      params = if angular.isObject(args[1]) then args.shift() else {}
      [postData, success, error] = args

      resource = @ || {}

      cacheEntry = new ResourceCacheEntry(resourceKey, params)
      if cacheEntry.dirty and angular.equals(cacheEntry.data, postData)
        # this exact request is already queued... just wait for it to finish.
        return resource

      # add this request to the write queue, unless it already exists
      # outstandingWrites = cache.getItem "#{resourceKey}/write", []
      # for write in outstandingWrites when write.action is action and angular.equals(write.params, params)
      #   outstandingWrite = write
      # unless outstandingWrite?

      resource = action.call(null, params, postData, success, error)

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
      if angular.isObject(arg[Object.keys(arg)[0]])
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
      action = angular.bind(Resource, Resource[name])
      if params.method is 'GET'
        CachedResource[name] = readCache(action, $key)
      else if params.method in ['POST', 'PUT', 'DELETE']
        CachedResource[name] = writeCache(action, $key)
      else
        CachedResource[name] = action

    cachedResources[$key] = CachedResource

    CachedResource
]

app
