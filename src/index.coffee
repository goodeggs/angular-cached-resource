DEFAULT_ACTIONS =
  get:    { method: 'GET',    }
  query:  { method: 'GET',    isArray: yes }
  save:   { method: 'POST',   }
  remove: { method: 'DELETE', }
  delete: { method: 'DELETE', }

ResourceCacheEntry = require './resource_cache_entry'
ResourceCacheArrayEntry = require './resource_cache_array_entry'
CachedResourceManager = require './cached_resource_manager'
resourceManagerListener = null

app = angular.module 'ngCachedResource', ['ngResource']

app.factory '$cachedResource', ['$resource', '$timeout', '$q', '$log', ($resource, $timeout, $q, $log) ->
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

  readArrayCache = (name, CachedResource) ->
    ->
      {params, deferred: cacheDeferred} = processReadArgs(arguments)
      httpDeferred = $q.defer()

      arrayInstance = new Array()
      arrayInstance.$promise = cacheDeferred.promise
      arrayInstance.$httpPromise = httpDeferred.promise

      cacheArrayEntry = new ResourceCacheArrayEntry(CachedResource.$key, params)

      resource = CachedResource.$resource[name].apply(CachedResource.$resource, arguments)
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
            cacheInstanceEntry = new ResourceCacheEntry(CachedResource.$key, cacheInstanceParams)
            cacheInstanceEntry.set instance, false
        cacheArrayEntry.set cacheArrayReferences

      if cacheArrayEntry.value
        for cacheInstanceParams in cacheArrayEntry.value
          cacheInstanceEntry = new ResourceCacheEntry(CachedResource.$key, cacheInstanceParams)
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
      resource = if instanceMethod
          @
        else
          new CachedResource(args.shift())
      [success, error] = args

      resource.$resolved = false
      params[param] = value for param, value of resource.$params()

      deferred = $q.defer()
      resource.$promise = deferred.promise
      deferred.promise.then success if angular.isFunction(success)
      deferred.promise.catch error if angular.isFunction(error)

      cacheEntry = new ResourceCacheEntry(CachedResource.$key, params)
      cacheEntry.set(resource, true) unless angular.equals(cacheEntry.data, resource)

      queueDeferred = $q.defer()
      queueDeferred.promise.then (value) ->
        angular.extend(resource, value)
        resource.$resolved = true
        deferred.resolve(resource)
      queueDeferred.promise.catch deferred.reject

      queue = resourceManager.getQueue(CachedResource)
      queue.enqueue(params, action, queueDeferred)
      queue.flush()

      resource

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
      @$resource: Resource
      @$key: $key

    for name, params of actions
      handler = if params.method is 'GET' and params.isArray
          readArrayCache(name, CachedResource)
        else if params.method is 'GET'
          readCache(name, CachedResource)
        else if params.method in ['POST', 'PUT', 'DELETE']
          writeCache(name, CachedResource)

      CachedResource[name] = handler
      CachedResource::["$#{name}"] = handler unless params.method is 'GET'

    resourceManager.add(CachedResource)
    resourceManager.flushQueues()

    CachedResource
]

module?.exports = app
