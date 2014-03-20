app = angular.module 'ngCachedResource', ['ngResource']

app.factory '$cachedResource', ['$resource', '$timeout', '$q', ($resource, $timeout, $q) ->
  LOCAL_STORAGE_PREFIX = 'cachedResource://'
  CACHE_RETRY_TIMEOUT = 60000 # one minute

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
    defaultValue: {}

    constructor: (resourceKey, params) ->
      @setKey(resourceKey)
      paramKeys = if angular.isObject(params) then Object.keys(params).sort() else []
      if paramKeys.length
        @key += '?' + ("#{param}=#{params[param]}" for param in paramKeys).join('&')
      {@value, @dirty} = cache.getItem(@key, @defaultValue)

    setKey: (@key) ->

    set: (@value) ->
      @dirty = yes
      @_update()

    clean: ->
      @dirty = no
      @_update()

    _update: ->
      cache.setItem @key, {@value, @dirty}

  class ResourceCacheArrayEntry extends ResourceCacheEntry
    defaultValue: []
    setKey: (key) -> @key = "#{key}/array"

  class ResourceWriteQueue
    constructor: (@CachedResource) ->
      @key = "#{@CachedResource.$key}/write"
      @queue = cache.getItem(@key, [])

    enqueue: (params, action, deferred) ->
      entry = @findEntry {params, action}
      if not entry?
        @queue.push {params, action, deferred}
        @_update()
      else
        entry.deferred.$promise.then (response) ->
          deferred.resolve response
        entry.deferred.$promise.catch (error) ->
          deferred.reject error

    findEntry: ({action, params}) ->
      for entry in @queue
        return entry if action is entry.action and angular.equals(params, entry.params)

    removeEntry: ({action, params}) ->
      newQueue = []
      for entry in @queue
        newQueue.push entry unless action is entry.action and angular.equals(params, entry.params)
      @queue = newQueue

      if @queue.length is 0 and @timeout
        $timeout.cancel @timeout
        delete @timeout

      @_update()

    flush: ->
      @_setFlushTimeout()
      for entry in @queue
        cacheEntry = new ResourceCacheEntry(@CachedResource.$key, entry.params)
        onSuccess = (value) =>
          @removeEntry entry
          entry.deferred.resolve value
        @CachedResource.$resource[entry.action](entry.params, cacheEntry.value, onSuccess, entry.deferred.reject)

    _setFlushTimeout: ->
      if @queue.length > 0 and not @timeout
        @timeout = $timeout angular.bind(@, @flush), CACHE_RETRY_TIMEOUT
        @timeout.then =>
          @_setFlushTimeout unless @queue.length is 0

    _update: ->
      savableQueue = @queue.map (entry) ->
        params: entry.params
        action: entry.actions
      cache.setItem @key, savableQueue

  CachedResourceManager =
    queuesByKey: {}
    add: (CachedResource) ->
      @queuesByKey[CachedResource.$key] = new ResourceWriteQueue(CachedResource)
    getQueue: (CachedResource) ->
      @queuesByKey[CachedResource.$key]
    flushQueues: ->
      queue.flush() for key, queue of @queuesByKey

  addEventListener 'online', (event) ->
    CachedResourceManager.flushQueues()

  readArrayCache = (name, CachedResource, boundParams) ->
    (parameters) ->
      resource = CachedResource.$resource[name].apply(CachedResource.$resource, arguments)
      resource.$httpPromise = resource.$promise

      parameters = {} if angular.isFunction parameters
      parameters ?= {}
      cacheArrayEntry = new ResourceCacheArrayEntry(CachedResource.$key, parameters)

      resource.$httpPromise.then (response) ->
        cacheArrayEntry.set response.map (instance) ->
          cacheInstanceParams = angular.copy(parameters)
          for attribute, param of boundParams when angular.isString(instance[attribute])
            cacheInstanceParams[param] = instance[attribute]
          cacheInstanceEntry = new ResourceCacheEntry(CachedResource.$key, cacheInstanceParams)
          cacheInstanceEntry.set instance
          cacheInstanceParams

      if cacheArrayEntry.value
        for cacheInstanceParams in cacheArrayEntry.value
          cacheInstanceEntry = new ResourceCacheEntry(CachedResource.$key, cacheInstanceParams)
          resource.push cacheInstanceEntry.value

        # Resolve the promise as the cache is ready
        deferred = $q.defer()
        resource.$promise = deferred.promise
        deferred.resolve resource

      resource

  readCache = (name, CachedResource) ->
    (parameters) ->
      resource = CachedResource.$resource[name].apply(CachedResource.$resource, arguments)
      resource.$httpPromise = resource.$promise

      parameters = null if angular.isFunction parameters
      cacheEntry = new ResourceCacheEntry(CachedResource.$key, parameters)

      resource.$httpPromise.then (response) ->
        cacheEntry.set response

      if cacheEntry.value
        angular.extend(resource, cacheEntry.value)

        # Resolve the promise as the cache is ready
        deferred = $q.defer()
        resource.$promise = deferred.promise
        deferred.resolve resource

      resource

  writeCache = (action, CachedResource) ->
    ->
      # according to the ngResource documentation:
      # Resource.action([parameters], postData, [success], [error])
      args = Array::slice.call arguments
      params = if angular.isObject(args[1]) then args.shift() else {}
      [postData, success, error] = args

      resource = @ || {}
      resource.$resolved = false

      deferred = $q.defer()
      resource.$promise = deferred.promise
      deferred.promise.then success if angular.isFunction(success)
      deferred.promise.catch error if angular.isFunction(error)

      cacheEntry = new ResourceCacheEntry(CachedResource.$key, params)
      cacheEntry.set(postData) unless angular.equals(cacheEntry.data, postData)

      queueDeferred = $q.defer()
      queueDeferred.promise.then (value) ->
        angular.extend(resource, value)
        resource.$resolved = true
        deferred.resolve(resource)
      queueDeferred.promise.catch deferred.reject

      queue = CachedResourceManager.getQueue(CachedResource)
      queue.enqueue(params, action, queueDeferred)
      queue.flush()

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
    # $cachedResource(resourceKey, url, [paramDefaults], [actions])
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

    boundParams = {}
    for param, paramDefault of paramDefaults when paramDefault[0] is '@'
      boundParams[paramDefault.substr(1)] = param

    for name, params of actions
      if params.method is 'GET' and params.isArray
        CachedResource[name] = readArrayCache(name, CachedResource, boundParams)
      else if params.method is 'GET'
        CachedResource[name] = readCache(name, CachedResource)
      else if params.method in ['POST', 'PUT', 'DELETE']
        CachedResource[name] = writeCache(name, CachedResource)
      else
        CachedResource[name] = angular.bind(Resource, Resource[name])

    CachedResourceManager.add(CachedResource)
    CachedResourceManager.flushQueues()

    CachedResource
]

app
