module.exports = (providerParams) ->
  {$log} = providerParams
  ResourceCacheEntry = require('./resource_cache_entry')(providerParams)

  class ResourceCacheArrayEntry extends ResourceCacheEntry
    defaultValue: []
    cacheKeyPrefix: -> "#{@key}/array"

    addInstances: (instances, dirty) ->
      cacheArrayReferences = []
      for instance in instances
        cacheInstanceParams = instance.$params()
        if Object.keys(cacheInstanceParams).length is 0
          $log.error """
            instance #{instance} doesn't have any boundParams. Please, make sure you specified them in your resource's initialization, f.e. `{id: "@id"}`, or it won't be cached.
          """
        else
          cacheArrayReferences.push cacheInstanceParams
          cacheInstanceEntry = new ResourceCacheEntry(@key, cacheInstanceParams).load()
          cacheInstanceEntry.set instance, dirty
      @set cacheArrayReferences, dirty
