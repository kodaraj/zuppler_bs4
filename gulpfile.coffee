Path                           = require('path')
gulp                           = require 'gulp'
gutil                          = require 'gulp-util'
gulpif                         = require 'gulp-if'
rename = require 'gulp-rename'
replace = require 'gulp-replace'
livereload = require 'gulp-livereload'
nodemon = require 'gulp-nodemon'
plumber = require 'gulp-plumber'
gwebpack = require 'webpack-stream'

sass = require 'gulp-sass'
prefixr   = require('gulp-autoprefixer')
CombineMq = require('gulp-combine-mq')
csso      = require('gulp-csso')

rimraf = require 'rimraf'
fs = require 'fs'

src_path        = "src"
components_path = "bower_components"
modules_path    = "node_modules"
dist_path       = "dist"

err = (x...) -> gutil.log(x...); gutil.beep(x...)

IS_PRODUCTION = 'production' is process.env.NODE_ENV or 'staging' is process.env.NODE_ENV
if IS_PRODUCTION
  console.log "BUILDING FOR #{process.env.NODE_ENV}"

SCSS_DIRS = [
  Path.resolve(__dirname, './node_modules/bootstrap-sass/assets/stylesheets')
  Path.resolve(__dirname, './src/styles')
]

gulp.task 'scss', ->
  gulp.src "#{src_path}/styles/**/*.scss"
  .pipe sass({ errLogToConsole: true, includePaths: SCSS_DIRS }).on('error', err)
  .pipe CombineMq()
  .pipe prefixr("last 1 version", "> 1%", "ie 8")
  .pipe csso()
  .pipe gulp.dest(dist_path + "/styles")
  .pipe gulpif(!IS_PRODUCTION, livereload())

gulp.task 'css', ['scss'], ->
  gulp
    .src(["#{src_path}/styles/**/*.css",
      './bower_components/zuppler-bootstrap/dist/styles/*.css',
      './node_modules/font-awesome/css/font-awesome.css'
    ])
    .pipe gulp.dest dist_path + "/styles"

gulp.task 'sounds', ->
  gulp
    .src ["#{src_path}/sounds/*.*"]
    .pipe gulp.dest dist_path + "/sounds"

gulp.task 'fonts', ->
  gulp.src "./node_modules/font-awesome/fonts/*"
  .pipe gulp.dest("#{dist_path}/fonts")

gulp.task 'clean', ->
  rimraf.sync(dist_path)

gulp.task 'copy', ['sounds'], ->
  gulp.src("#{src_path}/favicon.ico").pipe(gulp.dest(dist_path))

gulp.task 'watch', ->
  gulp.watch "#{src_path}/styles/**/*.scss", ['scss']

server_main = './server/server.coffee'
gulp.task 'server', ->
  nodemon
    script: server_main
    watch: [server_main]
    execMap:
      cjsx: "#{modules_path}/.bin/cjsx"
    env:
      PORT: process.env.PORT or 8080

gulp.task 'build', ['clean', 'copy', 'css', 'fonts']
gulp.task 'default', ['build']
