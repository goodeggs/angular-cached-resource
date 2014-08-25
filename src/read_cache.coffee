processReadArgs = require './process_read_args'
modifyObjectInPlace = require './modify_object_in_place'

module.exports = readCache = ($q, providerParams, name, CachedResource) ->
  ResourceCacheEntry = require('./resource_cache_entry')(providerParams)

  ->
    {params, deferred: cacheDeferred} = processReadArgs($q, arguments)
    httpDeferred = $q.defer()

    instance = new CachedResource
      $promise:     cacheDeferred.promise
      $httpPromise: httpDeferred.promise

    cacheEntry = new ResourceCacheEntry(CachedResource.$key, params).load()

    readHttp = ->
      resource = CachedResource.$resource[name].call(CachedResource.$resource, params)
      resource.$promise.then (httpResponse) ->
        modifyObjectInPlace(instance, httpResponse)

        cacheDeferred.resolve instance unless cacheEntry.value
        httpDeferred.resolve instance
        cacheEntry.set httpResponse, false
      resource.$promise.catch (error) ->
        cacheDeferred.reject error unless cacheEntry.value
        httpDeferred.reject error

    if cacheEntry.dirty
      CachedResource.$writes.processResource params, readHttp
    else
      readHttp()

    if cacheEntry.value
      angular.extend(instance, cacheEntry.value)
      cacheDeferred.resolve instance

    instance
