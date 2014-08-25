modifyObjectInPlace = require './modify_object_in_place'

module.exports = writeCache = ($q, providerParams, action, CachedResource) ->
  ResourceCacheEntry = require('./resource_cache_entry')(providerParams)

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
      cacheEntry.load()
      modifyObjectInPlace(data, httpResource, cacheEntry.value)
      data.$resolved = true
      deferred.resolve(data)
    queueDeferred.promise.catch deferred.reject

    CachedResource.$writes.enqueue(params, data, action, queueDeferred)
    CachedResource.$writes.flush()

    data
