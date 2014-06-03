CACHE_RETRY_TIMEOUT = 60000 # one minute

module.exports = (debug) ->
  ResourceCacheEntry = require('./resource_cache_entry')(debug)
  Cache = require('./cache')(debug)


  class ResourceWriteQueue
    logStatusOfRequest: (status, action, params, data) ->
      debug("ngCachedResource", "#{action} for #{@key} #{angular.toJson(params)} #{status}", data)

    constructor: (@CachedResource, @$timeout) ->
      @key = "#{@CachedResource.$key}/write"
      @queue = Cache.getItem(@key, [])

    enqueue: (params, resourceData, action, deferred) ->
      @logStatusOfRequest('enqueued', action, params, resourceData)
      resourceParams = if angular.isArray(resourceData)
        resourceData.map((resource) -> resource.$params())
      else
        resourceData.$params()

      write = @findWrite {params, action}
      if not write?
        @queue.push {params, resourceParams, action, deferred}
        @_update()
      else
        write.deferred?.promise.then (response) ->
          deferred.resolve response
        write.deferred?.promise.catch (error) ->
          deferred.reject error

    findWrite: ({action, params}) ->
      for write in @queue
        return write if action is write.action and angular.equals(params, write.params)

    removeWrite: ({action, params}) ->
      newQueue = []
      for entry in @queue
        newQueue.push entry unless action is entry.action and angular.equals(params, entry.params)
      @queue = newQueue

      if @queue.length is 0 and @timeoutPromise
        @$timeout.cancel @timeoutPromise
        delete @timeoutPromise

      @_update()

    flush: ->
      @_setFlushTimeout()
      @_processWrite(write) for write in @queue

    processResource: (params, done) ->
      notDone = true
      for write in @_writesForResource(params)
        @_processWrite write, =>
          if notDone and @_writesForResource(params).length is 0
            notDone = false
            done()

    _writesForResource: (params) ->
      # TODO FIX FIX FIXME this should compare against individual write.resourceParams, which could be a nested array
      write for write in @queue when angular.equals(params, write.params)

    _processWrite: (write, done) ->
      if angular.isArray(write.resourceParams)
        cacheEntries = write.resourceParams.map (resourceParams) =>
          new ResourceCacheEntry(@CachedResource.$key, resourceParams).load()
        writeData = cacheEntries.map (cacheEntry) -> cacheEntry.value
      else
        cacheEntries = [new ResourceCacheEntry(@CachedResource.$key, write.resourceParams).load()]
        writeData = cacheEntries[0].value

      @logStatusOfRequest('processed', write.action, write.resourceParams, writeData)

      onSuccess = (value) =>
        @logStatusOfRequest('succeeded', write.action, write.resourceParams, writeData)
        @removeWrite write
        cacheEntry.setClean() for cacheEntry in cacheEntries
        write.deferred?.resolve value
        done() if angular.isFunction(done)
      onFailure = (error) =>
        if error and error.status >= 400 and error.status < 500
          @removeWrite write
          @logStatusOfRequest("failed with error #{angular.toJson error}; removed from queue", write.action, write.resourceParams, writeData)
        else
          @logStatusOfRequest("failed with error #{angular.toJson error}; still in queue", write.action, write.resourceParams, writeData)
        write.deferred?.reject error
      @CachedResource.$resource[write.action](write.params, writeData, onSuccess, onFailure)

    _setFlushTimeout: ->
      if @queue.length > 0 and not @timeoutPromise
        @timeoutPromise = @$timeout angular.bind(@, @flush), CACHE_RETRY_TIMEOUT
        @timeoutPromise.then =>
          delete @timeoutPromise
          @_setFlushTimeout()

    _update: ->
      savableQueue = @queue.map (write) ->
        params: write.params
        resourceParams: write.resourceParams
        action: write.action
      Cache.setItem @key, savableQueue
