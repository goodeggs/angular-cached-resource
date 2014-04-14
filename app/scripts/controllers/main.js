'use strict';

angular.module('angularCachedResourceApp')
  .controller('MainCtrl', function ($scope, $state) {
    $scope.$state = $state;
  });
