# this is kind of like angular.extend(), except that if an attribute
# on newObject (or any of its children) is equivalent to the same
# attribute on oldObject, we won't overwrite it. This is useful if
# you are trying to keep track of deeply nested references to a
# resource's attributes from different scopes, for example.
module.exports = modifyObjectInPlace = (oldObject, newObject, cachedObject) ->
  # TODO the `when` clauses below are horrible hacks that need to be fixed
  for key in Object.keys(oldObject) when key[0] isnt '$'
    localChange = cachedObject and not cachedObject[key]?
    delete oldObject[key] unless newObject[key]? or localChange

  for key in Object.keys(newObject) when key[0] isnt '$'
    if angular.isObject(oldObject[key]) and angular.isObject(newObject[key])
      modifyObjectInPlace(oldObject[key], newObject[key], cachedObject?[key])
    else
      localChanges = cachedObject and not angular.equals(oldObject[key], cachedObject[key])
      unless angular.equals(oldObject[key], newObject[key]) or localChanges
        oldObject[key] = newObject[key]

  oldObject.length = newObject.length if newObject.length?

