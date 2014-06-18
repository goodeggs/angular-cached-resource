DEFAULT_ACTIONS =
  get:    { method: 'GET',    }
  query:  { method: 'GET',    isArray: yes }
  save:   { method: 'POST',   }
  remove: { method: 'DELETE', }
  delete: { method: 'DELETE', }

readArrayCache = require './read_array_cache'
readCache = require './read_cache'
writeCache = require './write_cache'

module.exports = buildCachedResourceClass = ($resource, $timeout, $q, debug, args) ->
  ResourceCacheEntry = require('./resource_cache_entry')(debug)
  ResourceCacheArrayEntry = require('./resource_cache_array_entry')(debug)
  ResourceWriteQueue = require('./resource_write_queue')(debug)
  Cache = require('./cache')(debug)

  resourceManager = @
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
        {queue, key} = CachedResource.$writes
        exceptForKeys.push key
        exceptFor.push resourceParams for {resourceParams} in queue

      for params in exceptFor
        resource = new CachedResource(params)
        exceptForKeys.push new ResourceCacheEntry($key, resource.$params()).key

      Cache.clear {key: $key, exceptFor: exceptForKeys}
    @$addToCache: (attrs) ->
      new CachedResource(attrs).$$addToCache()
    @$resource: Resource
    @$key: $key

  CachedResource.$writes = new ResourceWriteQueue(CachedResource, $timeout)

  for name, params of actions
    unless params.cache is false
      handler = if params.method is 'GET' and params.isArray
          readArrayCache($q, debug, name, CachedResource)
        else if params.method is 'GET'
          readCache($q, debug, name, CachedResource)
        else if params.method in ['POST', 'PUT', 'DELETE', 'PATCH']
          writeCache($q, debug, name, CachedResource)

      CachedResource[name] = handler
      CachedResource::["$#{name}"] = handler unless params.method is 'GET'
    else
      CachedResource[name] = Resource[name]
      CachedResource::["$#{name}"] = Resource::["$#{name}"]

  CachedResource
