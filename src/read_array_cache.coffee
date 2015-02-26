processReadArgs = require './process_read_args'
modifyObjectInPlace = require './modify_object_in_place'

module.exports = readArrayCache = ($q, providerParams, name, CachedResource, actionConfig) ->
  ResourceCacheEntry = require('./resource_cache_entry')(providerParams)
  ResourceCacheArrayEntry = require('./resource_cache_array_entry')(providerParams)

  first = (array, params) ->
    found = null

    for item in array
      itemParams = item.$params()
      if Object.keys(params).every((key) -> itemParams[key] is params[key])
        found = item
        break

    found

  ->
    {params, deferred: cacheDeferred} = processReadArgs($q, arguments)
    httpDeferred = $q.defer()

    arrayInstance = new Array()
    arrayInstance.$promise = cacheDeferred.promise
    arrayInstance.$httpPromise = httpDeferred.promise

    cacheParams = {}
    if actionConfig.cacheParamsKeys
      for key in actionConfig.cacheParamsKeys
        cacheParams[key] = params[key]
    else
      cacheParams = angular.copy(params);

    cacheArrayEntry = new ResourceCacheArrayEntry(CachedResource.$key, cacheParams).load()

    arrayInstance.$push = (resourceInstance) ->
      arrayInstance.push(resourceInstance)
      cacheArrayEntry.addInstances([resourceInstance], false, append: true)

    arrayInstance.$httpPromise.then (instances) ->
      cacheArrayEntry.addInstances(instances, false)

    readHttp = ->
      resource = CachedResource.$resource[name](params)
      resource.$promise.then (response) ->
        newArrayInstance = new Array()

        response.map (resourceInstance) ->
          resourceInstance = new CachedResource resourceInstance
          existingInstance = first(arrayInstance, resourceInstance.$params())

          if existingInstance
            modifyObjectInPlace(existingInstance, resourceInstance)
            newArrayInstance.push existingInstance
          else
            newArrayInstance.push resourceInstance

        arrayInstance.splice(0, arrayInstance.length, newArrayInstance...)

        cacheDeferred.resolve arrayInstance unless cacheArrayEntry.value
        httpDeferred.resolve arrayInstance
      resource.$promise.catch (error) ->
        cacheDeferred.reject error unless cacheArrayEntry.value
        httpDeferred.reject error

    if not actionConfig.cacheOnly
      CachedResource.$writes.flush readHttp

    if cacheArrayEntry.value
      for cacheInstanceParams in cacheArrayEntry.value
        cacheInstanceEntry = new ResourceCacheEntry(CachedResource.$key, cacheInstanceParams).load()
        arrayInstance.push new CachedResource cacheInstanceEntry.value

      # Resolve the promise as the cache is ready
      cacheDeferred.resolve arrayInstance
    else if actionConfig.cacheOnly
      cacheDeferred.reject new Error "Cache value does not exist for params", params

    arrayInstance
