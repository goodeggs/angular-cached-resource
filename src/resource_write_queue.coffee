CACHE_RETRY_TIMEOUT = 60000 # one minute

module.exports = (providerParams, $q) ->
  {$log} = providerParams
  ResourceCacheEntry = require('./resource_cache_entry')(providerParams)
  Cache = require('./cache')(providerParams)

  # this could be a lot nicer with ES6 WeakMaps
  # (http://www.nczonline.net/blog/2014/01/21/private-instance-members-with-weakmaps-in-javascript/)
  # but till then this is to maintain private instance members
  flushQueueDeferreds = {}
  resetDeferred = (queue) ->
    deferred = $q.defer()
    flushQueueDeferreds[queue.key] = deferred
    queue.promise = deferred.promise
    deferred
  resolveDeferred = (queue) ->
    flushQueueDeferreds[queue.key].resolve()

  class ResourceWriteQueue
    logStatusOfRequest: (status, action, params, data) ->
      $log.debug("#{action} for #{@key} #{angular.toJson(params)} #{status} (queue length: #{@queue.length})", data)

    constructor: (@CachedResource, @$timeout) ->
      @key = "#{@CachedResource.$key}/write"
      @queue = Cache.getItem(@key, [])
      resetDeferred(@)
      if @queue.length is 0
        resolveDeferred(@) # initialize the queue with a resolved promise

    enqueue: (params, resourceData, action, deferred) ->
      resetDeferred(@) if @queue.length is 0
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
      @logStatusOfRequest('enqueued', action, params, resourceData)

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

      resolveDeferred @ if @queue.length is 0

    flush: (done) ->
      @promise.then done if angular.isFunction(done)
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

      onSuccess = (value) =>
        @removeWrite write
        cacheEntry.setClean() for cacheEntry in cacheEntries
        write.deferred?.resolve value
        @logStatusOfRequest('succeeded', write.action, write.resourceParams, writeData)
        done() if angular.isFunction(done)
      onFailure = (error) =>
        if error and error.status >= 400 and error.status < 500
          @removeWrite write
          @logStatusOfRequest("failed with error #{angular.toJson error}; removed from queue", write.action, write.resourceParams, writeData)
        else
          @logStatusOfRequest("failed with error #{angular.toJson error}; still in queue", write.action, write.resourceParams, writeData)
        write.deferred?.reject error
      @CachedResource.$resource[write.action](write.params, writeData, onSuccess, onFailure)
      @logStatusOfRequest('processed', write.action, write.resourceParams, writeData)

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
