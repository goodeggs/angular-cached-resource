# according to the ngResource documentation:
# Resource.action([parameters], [success], [error])
module.exports = processReadArgs = ($q, args) ->
  args = Array::slice.call args
  params = if angular.isObject(args[0]) then args.shift() else {}
  [success, error] = args

  deferred = $q.defer()
  deferred.promise.then success if angular.isFunction success
  deferred.promise.catch error if angular.isFunction error

  {params, deferred}
