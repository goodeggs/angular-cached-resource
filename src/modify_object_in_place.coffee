# this is kind of like angular.extend(), except that if an attribute
# on newObject (or any of its children) is equivalent to the same
# attribute on oldObject, we won't overwrite it. This is useful if
# you are trying to keep track of deeply nested references to a
# resource's attributes from different scopes, for example.
module.exports = modifyObjectInPlace = (oldObject, newObject, cachedObject) ->
  # TODO the `when` clauses below are horrible hacks that need to be fixed
  for key in Object.keys(oldObject) when key[0] isnt '$'
    delete oldObject[key] unless newObject[key]?

  for key in Object.keys(newObject) when key[0] isnt '$'
    if angular.isObject(oldObject[key]) and angular.isObject(newObject[key])
      modifyObjectInPlace(oldObject[key], newObject[key], cachedObject?[key])
    else
      localChanges = cachedObject and not angular.equals(oldObject[key], cachedObject[key])
      if not angular.equals(oldObject[key], newObject[key]) and not localChanges
        oldObject[key] = newObject[key]
