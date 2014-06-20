processReadArgs = require './process_read_args'

module.exports = readArrayCache = ($q, log, name, CachedResource) ->
  ResourceCacheEntry = require('./resource_cache_entry')(log)
  ResourceCacheArrayEntry = require('./resource_cache_array_entry')(log)

  ->
    {params, deferred: cacheDeferred} = processReadArgs($q, arguments)
    httpDeferred = $q.defer()

    arrayInstance = new Array()
    arrayInstance.$promise = cacheDeferred.promise
    arrayInstance.$httpPromise = httpDeferred.promise

    cacheArrayEntry = new ResourceCacheArrayEntry(CachedResource.$key, params).load()

    arrayInstance.$httpPromise.then (response) ->
      cacheArrayReferences = []
      for instance in response
        cacheInstanceParams = instance.$params()
        if Object.keys(cacheInstanceParams).length is 0
          log.error """
            instance #{instance} doesn't have any boundParams. Please, make sure you specified them in your resource's initialization, f.e. `{id: "@id"}`, or it won't be cached.
          """
        else
          cacheArrayReferences.push cacheInstanceParams
          cacheInstanceEntry = new ResourceCacheEntry(CachedResource.$key, cacheInstanceParams).load()
          cacheInstanceEntry.set instance, false
      cacheArrayEntry.set cacheArrayReferences

    readHttp = ->
      resource = CachedResource.$resource[name](params)
      resource.$promise.then ->
        cachedResourceInstances = resource.map (resourceInstance) -> new CachedResource resourceInstance
        arrayInstance.splice(0, arrayInstance.length, cachedResourceInstances...)
        cacheDeferred.resolve arrayInstance unless cacheArrayEntry.value
        httpDeferred.resolve arrayInstance
      resource.$promise.catch (error) ->
        cacheDeferred.reject error unless cacheArrayEntry.value
        httpDeferred.reject error

    if CachedResource.$writes.count > 0
      CachedResource.$writes.flush readHttp
    else
      readHttp()

    if cacheArrayEntry.value
      for cacheInstanceParams in cacheArrayEntry.value
        cacheInstanceEntry = new ResourceCacheEntry(CachedResource.$key, cacheInstanceParams).load()
        arrayInstance.push new CachedResource cacheInstanceEntry.value

      # Resolve the promise as the cache is ready
      cacheDeferred.resolve arrayInstance

    arrayInstance
