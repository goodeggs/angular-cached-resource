app = angular.module 'cached-resource', []
online = yes

app.service 'cacheResource', ($q) ->

  (resource) ->
    cachedResource = {}
    if resource.get?
      cachedResource.get = (parameters, success, error) ->
        deferred = $q.defer()
        if online
          resource.get parameters, (route) ->
            #add to cache
            deferred.resolve(route)
        else
          deferred.resolve(fromCache)

        deferred.$promise
    cachedResource

app
