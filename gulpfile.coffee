FriendlyErrorsWebpackPlugin = require('friendly-errors-webpack-plugin')
notifier = new require('node-notifier').WindowsBalloon()
NodemonPlugin = require('nodemon-webpack-plugin')
nodeExternals = require('webpack-node-externals')
webpackMerge = require('webpack-merge')
webpack = require('webpack')
path = require('path')
gulp = require('gulp')
del = require('del')


process.noDeprecation = yes
#process.traceDeprecation = yes

ALIASES =
	'res'          : path.resolve './res'
	'core'         : path.resolve './src/core'
	'utils'        : path.resolve './src/core/utils'
	'config-client': path.resolve './config-client'
	'config'       : path.resolve './config'


BUILD_DIR = path.resolve './dist'

ENTRY =
	'bin/cli': './src/bin/cli.coffee'
	'index'  : './src/index.coffee'


BABEL_OPTIONS = {
	cacheDirectory: yes
	presets       : [
		['@babel/preset-env']
	]
	plugins       : [
		['@babel/plugin-transform-classes']
	]
}


createWebpackConfig = ->
	config =

		target   : 'node'
		mode     : 'production'
		devtool  : 'source-map'
		externals: [nodeExternals()]

		entry: ENTRY

		output:
			path    : BUILD_DIR
			filename: '[name].js'

		performance:
			hints: off

		resolve:
			extensions: ['.coffee', '.js']
	#			alias     : ALIASES

		plugins: [
			new FriendlyErrorsWebpackPlugin
				onErrors: onWebpackError
		]

		module:
			rules: createLoaders

				'.coffee':
					coffee: {}
					babel : BABEL_OPTIONS

				'.js':
					babel: BABEL_OPTIONS

	return config


onWebpackError = (severity, errors)=>
	notifier.notify
		sound  : off
		wait   : off
		time   : 2500
		title  : 'Webpack error',
		message: severity + ': ' + errors[0].name
	return


createLoaders = (options)=>
	rules = []

	for own extPattern, loaders of options
		extensions = extPattern.match(/\w+/img).join('|')
		regExp = new RegExp("\\.(#{extensions})$")

		loadersArr = []
		for own loaderName, loaderOptions of loaders
			loadersArr.unshift
				loader : "#{loaderName}-loader"
				options: loaderOptions

		rules.push
			test: regExp
			use : loadersArr

	return rules


clearBuildDir = =>
	return del(BUILD_DIR)


build = (callback)=>
	config = createWebpackConfig()
	return webpack(config, callback)


dev = (callback)=>
	config = webpackMerge createWebpackConfig(),

		mode   : 'development'
		devtool: 'eval-source-map'

		watch       : yes
		watchOptions:
			ignored: /node_modules/

		plugins: [
#			new NodemonPlugin(
#				watch   : path.resolve(BUILD_DIR)
#				script  : path.resolve(BUILD_DIR, 'index.js')
#				ignore  : ['*.js.map']
#				nodeArgs: ['--inspect']
#			)
		]

	return webpack(config, callback)



gulp.task('build', gulp.series(clearBuildDir, build))
gulp.task('dev', gulp.parallel(dev))
gulp.task('default', gulp.parallel('dev'))

