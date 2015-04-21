module.exports = (grunt)->
  require('grunt-jsdoc-plugin')
  require('load-grunt-tasks') grunt

  grunt.loadNpmTasks('grunt-codo');

  grunt.initConfig
    browserify:
      dist:
        files: 'Build/Tween.js': './Tween.coffee'
        options:
          transform: ['coffeeify']

    uglify:
      dist:
        files: 'Build/Tween.min.js': 'Build/Tween.js'

    watch:
      coffee:
        files: ['./Tween.coffee']
        tasks: ['build']
        options:
          livereload: 1338

    connect:
      server:
        options:
          open: false
          base: "Build"
          port: 9002
  grunt.registerTask 'build', ['browserify'] # 'uglify'
  grunt.registerTask 'default', ['build', 'connect', 'watch']
