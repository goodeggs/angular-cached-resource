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
      @_update()

    flush: ->
      for entry in @queue
        cacheEntry = new ResourceCacheEntry(@CachedResource.$key, entry.params)
        onSuccess = (value) =>
          @removeEntry entry
          entry.deferred.resolve value
        @CachedResource.$resource[entry.action](entry.params, cacheEntry.value, onSuccess, entry.deferred.reject)

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
        CachedResource[name] = writeCache(name, CachedResource)
      else
        CachedResource[name] = action

    CachedResourceManager.add(CachedResource)
    CachedResourceManager.flushQueues()

    CachedResource
]

app
