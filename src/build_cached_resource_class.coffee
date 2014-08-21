DEFAULT_ACTIONS =
  get:    { method: 'GET',    }
  query:  { method: 'GET',    isArray: yes }
  save:   { method: 'POST',   }
  remove: { method: 'DELETE', }
  delete: { method: 'DELETE', }

readArrayCache = require './read_array_cache'
readCache = require './read_cache'
writeCache = require './write_cache'

module.exports = buildCachedResourceClass = ($resource, $timeout, $q, providerParams, args) ->
  {$log} = providerParams
  ResourceCacheEntry = require('./resource_cache_entry')(providerParams)
  ResourceCacheArrayEntry = require('./resource_cache_array_entry')(providerParams)
  ResourceWriteQueue = require('./resource_write_queue')(providerParams, $q)
  Cache = require('./cache')(providerParams)

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

    $$addToCache: (dirty = false) ->
      entry = new ResourceCacheEntry($key, @$params())
      entry.set @, dirty
      @

    @$clearCache: ({where, exceptFor, clearPendingWrites, isArray, clearChildren} = {}) ->
      where ?= null
      exceptFor ?= null
      clearPendingWrites ?= false
      isArray ?= false
      clearChildren ?= false

      return $log.error "Using where and exceptFor arguments at once in $clearCache() method is forbidden!" if where && exceptFor

      cacheKeys = []

      translateParamsArrayToEntries = (entries) ->
        entries ||= []

        # Translate where and exceptFor objects to array of objects.
        # f.e. `{where: {id: 2}}` to `{where: [{id: 2}]}`
        entries = [entries] unless angular.isArray(entries)

        entries.map (entry) ->
          new CachedResource(entry).$params()

      translateEntriesToCacheKeys = (params_objects) ->
        params_objects.map (params) ->
          new ResourceCacheEntry($key, params).fullCacheKey()

      translateParamsArrayToCacheKeys = (entries) ->
        translateEntriesToCacheKeys translateParamsArrayToEntries entries

      if exceptFor || where
        if isArray
          cacheArrayEntry = new ResourceCacheArrayEntry($key, exceptFor || where).load()
          cacheKeys.push cacheArrayEntry.fullCacheKey()

          if cacheArrayEntry.value && ((exceptFor && !clearChildren) || (where && clearChildren))
            entries = (params for params in cacheArrayEntry.value)
            cacheKeys = cacheKeys.concat(translateEntriesToCacheKeys(entries)) if entries
        else
          cacheKeys = translateParamsArrayToCacheKeys(where || exceptFor)

      if !clearPendingWrites && !where
        {queue, key} = CachedResource.$writes
        cacheKeys.push key
        entries = queue.map (resource) -> resource.resourceParams
        cacheKeys = cacheKeys.concat translateEntriesToCacheKeys(entries)
      else if clearPendingWrites && where
        $log.debug "TODO if clearPendingWrites && where"
        # TODO clear only those writes, which match :where parameter

      if where
        Cache.clear {key: $key, where: cacheKeys}
      else
        Cache.clear {key: $key, exceptFor: cacheKeys}


    @$addToCache: (attrs, dirty) ->
      new CachedResource(attrs).$$addToCache(dirty)

    @$addArrayToCache: (attrs, instances, dirty = false) ->
      instances = instances.map (instance) ->
        new CachedResource(instance)
      new ResourceCacheArrayEntry($key, attrs).addInstances instances, dirty

    @$resource: Resource
    @$key: $key

  CachedResource.$writes = new ResourceWriteQueue(CachedResource, $timeout)

  for name, params of actions
    method = params.method.toUpperCase()
    unless params.cache is false
      handler = if method is 'GET' and params.isArray
          readArrayCache($q, providerParams, name, CachedResource)
        else if method is 'GET'
          readCache($q, providerParams, name, CachedResource)
        else if method in ['POST', 'PUT', 'DELETE', 'PATCH']
          writeCache($q, providerParams, name, CachedResource)

      CachedResource[name] = handler
      CachedResource::["$#{name}"] = handler unless method is 'GET'
    else
      CachedResource[name] = Resource[name]
      CachedResource::["$#{name}"] = Resource::["$#{name}"]

  CachedResource
