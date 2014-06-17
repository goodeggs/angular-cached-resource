DEFAULT_ACTIONS =
  get:    { method: 'GET',    }
  query:  { method: 'GET',    isArray: yes }
  save:   { method: 'POST',   }
  remove: { method: 'DELETE', }
  delete: { method: 'DELETE', }

resourceManagerListener = null
debugMode = off

module?.exports = app = angular.module 'ngCachedResource', ['ngResource']
app.provider '$cachedResource', class $cachedResourceProvider
  constructor: ->
    @$get = $cachedResourceFactory
  setDebugMode: (newSetting = on) ->
    debugMode = newSetting

$cachedResourceFactory = ['$resource', '$timeout', '$q', '$log', ($resource, $timeout, $q, $log) ->

  debug = if debugMode then angular.bind($log, $log.debug, 'ngCachedResource') else (->)

  ResourceCacheEntry = require('./resource_cache_entry')(debug)
  ResourceCacheArrayEntry = require('./resource_cache_array_entry')(debug)
  CachedResourceManager = require('./cached_resource_manager')(debug)
  cache = require('./cache')(debug)

  resourceManager = new CachedResourceManager($timeout)

  document.removeEventListener 'online', resourceManagerListener if resourceManagerListener
  resourceManagerListener = (event) -> resourceManager.flushQueues()
  document.addEventListener 'online', resourceManagerListener

  processReadArgs = (args) ->
    # according to the ngResource documentation:
    # Resource.action([parameters], [success], [error])
    args = Array::slice.call args
    params = if angular.isObject(args[0]) then args.shift() else {}
    [success, error] = args

    deferred = $q.defer()
    deferred.promise.then success if angular.isFunction success
    deferred.promise.catch error if angular.isFunction error

    {params, deferred}

  # this is kind of like angular.extend(), except that if an attribute
  # on newObject (or any of its children) is equivalent to the same
  # attribute on oldObject, we won't overwrite it. This is useful if
  # you are trying to keep track of deeply nested references to a
  # resource's attributes from different scopes, for example.
  modifyObjectInPlace = (oldObject, newObject) ->
    # the `when` clauses below are horrible hacks that needs to be fixed
    for key in Object.keys(oldObject) when key[0] isnt '$'
      delete oldObject[key] unless newObject[key]?
    for key in Object.keys(newObject) when key[0] isnt '$'
      if angular.isObject(oldObject[key]) and angular.isObject(newObject[key])
        modifyObjectInPlace(oldObject[key], newObject[key])
      else if not angular.equals(oldObject[key], newObject[key])
        oldObject[key] = newObject[key]

  readArrayCache = (name, CachedResource) ->
    ->
      {params, deferred: cacheDeferred} = processReadArgs(arguments)
      httpDeferred = $q.defer()

      arrayInstance = new Array()
      arrayInstance.$promise = cacheDeferred.promise
      arrayInstance.$httpPromise = httpDeferred.promise

      cacheArrayEntry = new ResourceCacheArrayEntry(CachedResource.$key, params).load()

      resource = CachedResource.$resource[name](params)
      resource.$promise.then ->
        cachedResourceInstances = resource.map (resourceInstance) -> new CachedResource resourceInstance
        arrayInstance.splice(0, arrayInstance.length, cachedResourceInstances...)
        cacheDeferred.resolve arrayInstance unless cacheArrayEntry.value
        httpDeferred.resolve arrayInstance
      resource.$promise.catch (error) ->
        cacheDeferred.reject error unless cacheArrayEntry.value
        httpDeferred.reject error

      arrayInstance.$httpPromise.then (response) ->
        cacheArrayReferences = []
        for instance in response
          cacheInstanceParams = instance.$params()
          if Object.keys(cacheInstanceParams).length is 0
            $log.error """
              instance #{instance} doesn't have any boundParams. Please, make sure you specified them in your resource's initialization, f.e. `{id: "@id"}`, or it won't be cached.
            """
          else
            cacheArrayReferences.push cacheInstanceParams
            cacheInstanceEntry = new ResourceCacheEntry(CachedResource.$key, cacheInstanceParams).load()
            cacheInstanceEntry.set instance, false
        cacheArrayEntry.set cacheArrayReferences

      if cacheArrayEntry.value
        for cacheInstanceParams in cacheArrayEntry.value
          cacheInstanceEntry = new ResourceCacheEntry(CachedResource.$key, cacheInstanceParams).load()
          arrayInstance.push new CachedResource cacheInstanceEntry.value

        # Resolve the promise as the cache is ready
        cacheDeferred.resolve arrayInstance

      arrayInstance

  readCache = (name, CachedResource) ->
    ->
      {params, deferred: cacheDeferred} = processReadArgs(arguments)
      httpDeferred = $q.defer()

      instance = new CachedResource
        $promise:     cacheDeferred.promise
        $httpPromise: httpDeferred.promise

      cacheEntry = new ResourceCacheEntry(CachedResource.$key, params).load()

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
        resourceManager.getQueue(CachedResource).processResource params, readHttp
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
      data = if instanceMethod then @ else args.shift()
      [success, error] = args

      isArray = angular.isArray(data)

      wrapInCachedResource = (object) ->
        if object instanceof CachedResource
          object
        else
          new CachedResource object

      if isArray
        data = data.map((o) -> wrapInCachedResource o)
        for resource in data
          cacheEntry = new ResourceCacheEntry(CachedResource.$key, resource.$params()).load()
          cacheEntry.set(resource, true) unless angular.equals(cacheEntry.data, resource)
      else
        data = wrapInCachedResource data
        params[param] = value for param, value of data.$params()
        cacheEntry = new ResourceCacheEntry(CachedResource.$key, data.$params()).load()
        cacheEntry.set(data, true) unless angular.equals(cacheEntry.data, data)

      data.$resolved = false

      deferred = $q.defer()
      data.$promise = deferred.promise
      deferred.promise.then success if angular.isFunction(success)
      deferred.promise.catch error if angular.isFunction(error)

      queueDeferred = $q.defer()
      queueDeferred.promise.then (httpResource) ->
        modifyObjectInPlace(data, httpResource)
        data.$resolved = true
        deferred.resolve(data)
      queueDeferred.promise.catch deferred.reject

      queue = resourceManager.getQueue(CachedResource)
      queue.enqueue(params, data, action, queueDeferred)
      queue.flush()

      data

  $cachedResource = ->
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
    actions = angular.extend({}, DEFAULT_ACTIONS, actions)
    paramDefaults ?= {}

    boundParams = {}
    for param, paramDefault of paramDefaults when paramDefault[0] is '@'
      boundParams[paramDefault.substr(1)] = param

    Resource = $resource.call(null, url, paramDefaults, actions)

    isPermissibleBoundValue = (value) ->
      angular.isDate(value) or angular.isNumber(value) or angular.isString(value)

    class CachedResource
      $cache: true # right now this is just a flag, eventually it could be useful for cache introspection (see https://github.com/goodeggs/angular-cached-resource/issues/8)
      constructor: (attrs) ->
        angular.extend @, attrs
      $params: ->
        params = {}
        for attribute, param of boundParams when isPermissibleBoundValue @[attribute]
          params[param] = @[attribute]
        params
      $$addToCache: ->
        entry = new ResourceCacheEntry($key, @$params())
        entry.set @, yes
        @
      @$clearAll: ({exceptFor, clearPendingWrites} = {}) ->
        exceptForKeys = []

        if angular.isObject(exceptFor) # FYI this is going to change soon; see https://github.com/goodeggs/angular-cached-resource/issues/8
          cacheArrayEntry = new ResourceCacheArrayEntry($key, exceptFor).load()
          exceptForKeys.push cacheArrayEntry.key
          if cacheArrayEntry.value
            exceptFor = (params for params in cacheArrayEntry.value)

        exceptFor ?= []
        unless clearPendingWrites
          {queue, key} = resourceManager.getQueue(CachedResource)
          exceptForKeys.push key
          exceptFor.push resourceParams for {resourceParams} in queue

        for params in exceptFor
          resource = new CachedResource(params)
          exceptForKeys.push new ResourceCacheEntry($key, resource.$params()).key

        cache.clear {key: $key, exceptFor: exceptForKeys}
      @$addToCache: (attrs) ->
        new CachedResource(attrs).$$addToCache()
      @$resource: Resource
      @$key: $key

    for name, params of actions
      handler = if params.method is 'GET' and params.isArray
          readArrayCache(name, CachedResource)
        else if params.method is 'GET'
          readCache(name, CachedResource)
        else if params.method in ['POST', 'PUT', 'DELETE', 'PATCH']
          writeCache(name, CachedResource)

      CachedResource[name] = handler
      CachedResource::["$#{name}"] = handler unless params.method is 'GET'

    resourceManager.add(CachedResource)
    resourceManager.flushQueues()

    CachedResource

  for fn in ['clearAll', 'clearUndefined']
    $cachedResource[fn] = angular.bind resourceManager, resourceManager[fn]

  return $cachedResource
]
