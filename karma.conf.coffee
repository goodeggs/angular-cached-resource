module.exports = (config) ->

  config.set
    frameworks: [
      'mocha'
      'sinon-chai'
      'browserify'
    ]

    files: [
      'bower_components/angular/angular.js'
      'bower_components/angular-mocks/angular-mocks.js'
      'bower_components/angular-resource/angular-resource.js'

      'src/index.coffee'

      'test/_config.coffee'
      'test/*.test.coffee'
    ]

    browsers: [
      'PhantomJS'
    ]

    preprocessors:
      '**/*.coffee': ['coffee']
      'src/**/*.coffee': ['browserify']

    browserify:
      extensions: ['.coffee']
      transform: ['coffeeify']
      watch: yes
      debug: yes
