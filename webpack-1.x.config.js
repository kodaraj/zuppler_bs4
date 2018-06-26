var path = require('path');
var webpack = require('webpack');
var CompressionPlugin = require("compression-webpack-plugin");
var WebpackErrorNotificationPlugin = require('webpack-error-notification');
var HtmlWebpackPlugin = require('html-webpack-plugin');
var ExtractTextPlugin = require("extract-text-webpack-plugin");
var WebpackStrip = require('webpack-strip');
var VersionFile =  require("webpack-version-file-plugin");

var isProduction = ( 'production' == process.env.NODE_ENV );
var isStaging = ( 'staging' == process.env.NODE_ENV );
var isDevelopment = !(isProduction || isStaging);

console.log("[WEBPACK] BUILDING FOR:", process.env.NODE_ENV || 'development');

var config = module.exports = {
  // the base path which will be used to resolve entry points
  context: __dirname,
  // the main entry point for our application's frontend JS
  entry: {
    main: "./src/scripts/main.coffee",
    auth: "./src/scripts/auth.coffee"
  },
  devtool: (isDevelopment ? "#inline-source-map" :  "hidden" )
};

if (isDevelopment) {
  config.entry.dev ='webpack/hot/only-dev-server';
  config.entry.client = 'webpack-dev-server/client?http://0.0.0.0:8080';
}

config.node = {
  net: 'empty',
  tls: 'empty',
  target: 'web'
};

config.output = {
  // this is our app/assets/javascripts directory, which is part of the Sprockets pipeline
  path: path.join(__dirname, 'dist'),
  // the filename of the compiled bundle, e.g. app/assets/javascripts/bundle.js
  filename: ( isDevelopment ? '[name].js' : '[name].[hash].js' ),
  // if the webpack code-splitting feature is enabled, this is the path it'll use to download bundles
  publicPath: '/',
  devtoolModuleFilenameTemplate: '[resourcePath]',
  devtoolFallbackModuleFilenameTemplate: '[resourcePath]?[hash]'
};

config.resolve = {
  extensions: ['', '.js', '.jsx', '.coffee', '.cjsx'],
  modulesDirectories: [ 'node_modules', 'bower_components', "src/scripts" ],
  alias: { cldr: 'cldrjs', fs: 'brfs' },
  root: [path.join(__dirname, "bower_components"), path.join(__dirname, "./src/scripts")]
};

prodPlugins = [
  new webpack.optimize.DedupePlugin(),
  new webpack.optimize.OccurenceOrderPlugin(true),
  new webpack.DefinePlugin({
    APP_CLIENT_ID: process.env.APP_CLIENT_ID,
    USERS_SERVER: process.env.USERS_SERVER,
    FEEDBACK_SVC: process.env.FEEDBACK_SVC,
    AUTH_CALLBACK_URL: process.env.AUTH_CALLBACK_URL,
    GOOGLE_API_KEY: process.env.GOOGLE_API_KEY,
    VERSION: JSON.stringify(require("./package.json").version)
  }),
  new webpack.optimize.UglifyJsPlugin({compress: {warnings: false}}),
  new CompressionPlugin({
    asset: "[path].gz[query]",
    algorithm: "zopfli",
    test: /\.js$|\.html$/,
    threshold: 10240,
    minRatio: 0.8
  })
];

devPlugins = [
  new webpack.DefinePlugin({
    APP_CLIENT_ID: "'cf84cc73b22bba6dc46f044c5aa94fff781e78c36d8b2ae60a4b0c2846fe7f10'",
    USERS_SERVER: '"https://users.zuppler.com"',
    FEEDBACK_SVC: '"http://feedback.zuppler.com"',
    AUTH_CALLBACK_URL: '"http://localhost:8080/auth.html"',
    GOOGLE_API_KEY: "'AIzaSyCAIsQ7Fi9LZg3_YBRjynkRyHk2Y34robg'",
    VERSION: JSON.stringify(require("./package.json").version)
  }),
  new WebpackErrorNotificationPlugin('darwin')
];

var envPlugins = function() {
  env = process.env.NODE_ENV || 'development';
  switch(env.toLowerCase()) {
  case 'production': return prodPlugins;
  case 'staging': return prodPlugins;
  default: return devPlugins;
  }
};

var sassLoaderPaths = [
  path.resolve(__dirname, './node_modules/bootstrap-sass/assets/stylesheets'),
  path.resolve(__dirname, './src/styles')
];

var sassLoaderConfig = sassLoaderPaths.reduce(((url, path) => "#{url}includePaths[]=#{path}&"), "sass-loader?");

config.plugins = [
  new webpack.ResolverPlugin([
    new webpack.ResolverPlugin.DirectoryDescriptionFilePlugin(['.bower.json', 'bower.json'], ['main'])
  ]),
  new webpack.optimize.CommonsChunkPlugin('common.bundle.js'),
  new webpack.DefinePlugin({
    'process.env': {'NODE_ENV': JSON.stringify(process.env.NODE_ENV)},
  }),
  new webpack.ContextReplacementPlugin(/moment[\/\\]locale$/, /en/),
  new HtmlWebpackPlugin({
    template: 'src/index.html',
    inject: 'body',
    excludeChunks: ['auth'],
    hash: !isDevelopment
  }),
  new HtmlWebpackPlugin({
    template: 'src/auth.html',
    filename: 'auth.html',
    excludeChunks: ['main'],
    inject: 'body',
    hash: !isDevelopment
  }),
  // new ExtractTextPlugin("main.css"),
  new VersionFile({
    packageFile:path.join(__dirname, 'package.json'),
    template: path.join(__dirname, 'version.ejs'),
    outputFile: path.join(__dirname, 'dist', 'version.json')
  })
].concat(envPlugins());

var devLoaders = [
  { test: /\.cjsx$/, loaders: [ 'react-hot', 'coffee-loader', 'cjsx-loader']},
];
var prodLoaders = [
  { test: [/\.js$/, /\.jsx$/, /\.coffee$/, /\.cjsx$/], exclude: [new RegExp("node_modules"), new RegExp("bower_components")], loader: WebpackStrip.loader('console.log', 'console.error', 'console.info') },
  { test: /\.cjsx$/, loaders: [ 'coffee-loader', 'cjsx-loader']}
];
var commonLoaders = [
  { test: [/\.js$/, /\.jsx$/], loader: "babel-loader", exclude: [new RegExp("node_modules"), new RegExp("bower_components")] },
  // { test: /\.js$/, loader: "transform?brfs" },
  { test: /\.coffee$/, loader: 'coffee-loader' },
  { test: /\.scss$/, loader: sassLoaderConfig },
  { test: /bootstrap\/js\//, loader: 'imports?jQuery=jquery' },
  { test: [ /\.woff/, /\.woff2/ ], loader: "url-loader?limit=10000&minetype=application/font-woff&name=fonts/[name]-[hash].[ext]" },
  { test: /\.ttf/,   loader: "file-loader?name=fonts/[name]-[hash].[ext]" },
  { test: /\.eot/,   loader: "file-loader?name=fonts/[name]-[hash].[ext]" },
  { test: /\.svg/,   loader: "file-loader?name=fonts/[name]-[hash].[ext]" },
  { test: /\.png/,   loader: "file-loader?name=images/[name]-[hash].[ext]" },
  { test: /\.css/,   loader: 'style-loader!css-loader' },
  { test: /\.json/,  loader: "json-loader" }
];

config.module = {
  loaders: (isDevelopment ? devLoaders : prodLoaders).concat(commonLoaders)
};
