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

    set: (@value, @dirty) ->
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
      @_processEntry(entry) for entry in @queue


    processResource: (params, done) ->
      notDone = true
      for entry in @_entriesForResource(params)
        @_processEntry entry, =>
          if notDone and @_entriesForResource(params).length is 0
            notDone = false
            done()

    _entriesForResource: (params) ->
      entry for entry in @queue when angular.equals(params, entry.params)

    _processEntry: (entry, done) ->
      cacheEntry = new ResourceCacheEntry(@CachedResource.$key, entry.params)
      onSuccess = (value) =>
        @removeEntry entry
        entry.deferred?.resolve value
        done() if angular.isFunction(done)
      onFailure = (error) =>
        entry.deferred?.reject error
      @CachedResource.$resource[entry.action](entry.params, cacheEntry.value, onSuccess, onFailure)

    _setFlushTimeout: ->
      if @queue.length > 0 and not @timeout
        @timeout = $timeout angular.bind(@, @flush), CACHE_RETRY_TIMEOUT
        @timeout.then =>
          delete @timeout
          @_setFlushTimeout()

    _update: ->
      savableQueue = @queue.map (entry) ->
        params: entry.params
        action: entry.action
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
          cacheInstanceParams = {}
          for attribute, param of boundParams when angular.isString(instance[attribute])
            cacheInstanceParams[param] = instance[attribute]
          cacheInstanceEntry = new ResourceCacheEntry(CachedResource.$key, cacheInstanceParams)
          cacheInstanceEntry.set instance, false
          cacheInstanceParams

      if cacheArrayEntry.value
        for cacheInstanceParams in cacheArrayEntry.value
          cacheInstanceEntry = new ResourceCacheEntry(CachedResource.$key, cacheInstanceParams)
          resource.push new CachedResource cacheInstanceEntry.value

        # Resolve the promise as the cache is ready
        deferred = $q.defer()
        resource.$promise = deferred.promise
        deferred.resolve resource

      resource

  readCache = (name, CachedResource) ->
    ->
      # according to the ngResource documentation:
      # Resource.action([parameters], [success], [error])
      args = Array::slice.call arguments
      params = if angular.isObject(args[0]) then args.shift() else {}
      [success, error] = args

      cacheDeferred = $q.defer()
      cacheDeferred.promise.then success if angular.isFunction success
      cacheDeferred.promise.catch error if angular.isFunction error

      httpDeferred = $q.defer()

      instance = new CachedResource
        $promise:     cacheDeferred.promise
        $httpPromise: httpDeferred.promise

      cacheEntry = new ResourceCacheEntry(CachedResource.$key, params)

      readHttp = ->
        resource = CachedResource.$resource[name].call(CachedResource.$resource, params)
        resource.$promise.then (response) ->
          angular.extend(instance, response)
          cacheDeferred.resolve instance unless cacheEntry.value
          httpDeferred.resolve instance
          cacheEntry.set response, false
        resource.$promise.catch (error) ->
          cacheDeferred.reject error unless cacheEntry.value
          httpDeferred.reject error

      if cacheEntry.dirty
        CachedResourceManager.getQueue(CachedResource).processResource params, readHttp
      else
        readHttp()

      if cacheEntry.value
        angular.extend(instance, cacheEntry.value)
        cacheDeferred.resolve instance

      instance

  writeCache = (action, CachedResource) ->
    ->
      # according to the ngResource documentation:
      # Resource.action([parameters], postData, [success], [error])
      # or
      # resourceInstance.action([parameters], [success], [error])
      instanceMethod = @ instanceof CachedResource
      args = Array::slice.call arguments
      params =
        if not instanceMethod and angular.isObject(args[1])
          args.shift()
        else if instanceMethod and angular.isObject(args[0])
          args.shift()
        else
          {}
      postData = if instanceMethod then @ else args.shift()
      [success, error] = args

      resource = @ || new CachedResource()
      resource.$resolved = false

      deferred = $q.defer()
      resource.$promise = deferred.promise
      deferred.promise.then success if angular.isFunction(success)
      deferred.promise.catch error if angular.isFunction(error)

      cacheEntry = new ResourceCacheEntry(CachedResource.$key, params)
      cacheEntry.set(postData, true) unless angular.equals(cacheEntry.data, postData)

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

    boundParams = {}
    for param, paramDefault of paramDefaults when paramDefault[0] is '@'
      boundParams[paramDefault.substr(1)] = param

    Resource = $resource.call(null, url, paramDefaults, actions)

    class CachedResource
      constructor: (attrs) ->
        angular.extend @, attrs
      @$resource: Resource
      @$key: $key

    for name, params of actions
      handler = if params.method is 'GET' and params.isArray
          readArrayCache(name, CachedResource, boundParams)
        else if params.method is 'GET'
          readCache(name, CachedResource)
        else if params.method in ['POST', 'PUT', 'DELETE']
          writeCache(name, CachedResource)
      CachedResource::["$#{name}"] = handler unless params.method is 'GET'
      CachedResource[name] = handler

    CachedResourceManager.add(CachedResource)
    CachedResourceManager.flushQueues()

    CachedResource
]

app
