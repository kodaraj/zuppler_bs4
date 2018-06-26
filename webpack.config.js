const path = require("path");
const webpack = require("webpack");
const HtmlWebpackPlugin = require("html-webpack-plugin")
const VersionFile = require("webpack-version-file-plugin")
let isDevelopment = !process.env.NODE_ENV || process.env.NODE_ENV == "development"

const getConfigMode = (env) => {
  if (env === "production")
    return "production"
  else
    return "development"
}

const getEnvVars = (env) => {
  let vars = null
  switch(env) {
    case "production":
      vars = {
        APP_CLIENT_ID: JSON.stringify(process.env.APP_CLIENT_ID || "39fec32cb0674f0962e763be3f905e7dcd50f70f1e5bd117433133a6d43bbff1"),
        GOOGLE_API_KEY: JSON.stringify(process.env.GOOGLE_API_KEY || "AIzaSyCAIsQ7Fi9LZg3_YBRjynkRyHk2Y34robg"),
        AUTH_CALLBACK_URL: JSON.stringify(process.env.AUTH_CALLBACK_URL || "http://customer-service.zuppler.com/auth.html"),
        USERS_SERVER: JSON.stringify(process.env.USERS_SERVER || "https://users.zuppler.com"),
        FEEDBACK_SVC: JSON.stringify(process.env.FEEDBACK_SVC || "http://feedback.zuppler.com"),
        ORDERS_SVC: JSON.stringify(process.env.ORDERS_SVC || "https://orders-api.zuppler.com"),
        REPORTS_SVC: JSON.stringify(process.env.REPORTS_SVC || "https://reports.zuppler.com"),
        RDSAAS_SVC: JSON.stringify(process.env.RDSAAS_SVC || "https://rdsaas.zuppler.com"),
        API3_SVC: JSON.stringify(process.env.API3_SVC || "https://api.zuppler.com"),
        CP_SVC: JSON.stringify(process.env.CP_SVC || "http://restaurants.zuppler.com"),
        PRESENCE_SVC: JSON.stringify(process.env.PRESENCE_SVC || "ws://zuppler-presence.herokuapp.com")
      }
      break;
    default:
      vars = {
        APP_CLIENT_ID: JSON.stringify("cf84cc73b22bba6dc46f044c5aa94fff781e78c36d8b2ae60a4b0c2846fe7f10"),
        GOOGLE_API_KEY: JSON.stringify("AIzaSyCAIsQ7Fi9LZg3_YBRjynkRyHk2Y34robg"),
        AUTH_CALLBACK_URL: JSON.stringify( "http://localhost:8080/auth.html" ),
        USERS_SERVER: JSON.stringify(process.env.USERS_SERVER || "https://users.zuppler.com"),
        FEEDBACK_SVC: JSON.stringify(process.env.FEEDBACK_SVC || "http://feedback.zuppler.com"),
        ORDERS_SVC: JSON.stringify(process.env.ORDERS_SVC || "https://orders-api.zuppler.com"),
        REPORTS_SVC: JSON.stringify(process.env.REPORTS_SVC || "https://reports.zuppler.com"),
        RDSAAS_SVC: JSON.stringify(process.env.RDSAAS_SVC || "https://rdsaas.zuppler.com"),
        API3_SVC: JSON.stringify(process.env.API3_SVC || "https://api.zuppler.com"),
        CP_SVC: JSON.stringify(process.env.CP_SVC || "http://restaurants.zuppler.com"),
        PRESENCE_SVC: JSON.stringify(process.env.PRESENCE_SVC || "ws://zuppler-presence.herokuapp.com")
      }
  }
  console.log(`[${env || "development"}] Using vars`, JSON.stringify(vars, null, 2))
  return vars
}

module.exports = {
  mode: getConfigMode(process.env.NODE_ENV), // "production" | "development" | "none"

  entry: {
    main: "./src/scripts/main",
    auth: "./src/scripts/auth",
    notifications: "./src/scripts/notifications"
  },
  // Here the application starts executing
  // and webpack starts bundling

  output: {
    // options related to how webpack emits results

    path: path.resolve(__dirname, "dist"), // string
    // the target directory for all output files
    // must be an absolute path (use the Node.js path module)

    filename: "[name].js", // string
    // the filename template for entry chunks

    publicPath: "/", // string
    // the url to the output directory resolved relative to the HTML page

    // library: "MyLibrary", // string,
    // the name of the exported library

    libraryTarget: "umd", // universal module definition
    // the type of the exported library

    /* Advanced output configuration (click to show) */
  },

  module: {
    // configuration regarding modules

    rules: [
      {
        test: /\.jsx?$/,
        include: [
          path.resolve(__dirname, "./src/scripts")
        ],
        loader: "babel-loader",
        options: {
          presets: ["env"]
        },
      },
      {
        test: [ /\.coffee$/, /\.cjsx$/ ],
        use: [
          {
            loader: "coffee-loader",
            options: {
              transpile: {
                presets: ["react", "env"]
              }
            }
          }
        ]
      },
      // {
      //   test: /\.css$/,
      //   use: [
      //     { loader: "style-loader" },
      //     { loader: "css-loader",
      //       options: {
      //         importLoaders: 2
      //       }
      //     }
      //   ]
      // },
      {
        // For all .css files except from node_modules
        test: /\.css$/,
        exclude: /node_modules/,
        use: [
          { loader: "style-loader"},
          { loader: "css-loader", options: { modules: true } }
        ]
      },
      {
        // For all .css files in node_modules
        test: /\.css$/,
        include: /node_modules/,
        use: ["style-loader", "css-loader"]
      },
      {
        test: /\.scss$/,
        use: [
          {
            loader: "style-loader"
          },
          {
            loader: "css-loader",
            options: {
              importLoaders: 2
            }
          },
          {
          loader: 'postcss-loader',
            options: {
              plugins() {
                return [
                  require('precss'),
                  require('autoprefixer'),
                ];
              },
            },
          },
          {
            loader: "sass-loader"
          }
        ]
      },
      {
        test: /\.(png|jpg|gif|svg|eot|ttf|woff|woff2)$/,
        loader: "url-loader",
        options: {
          limit: 10000
        }
      }
    ],
  },

  resolve: {
    // options for resolving module requests
    // (does not apply to resolving to loaders)

    modules: [
      "node_modules",
      path.resolve(__dirname, "./src/scripts"),
      // path.resolve(__dirname,  "./node_modules/bootstrap-sass/assets/stylesheets"),
      path.resolve(__dirname, "./src/styles")
    ],
    // directories where to look for modules

    extensions: [".js", ".jsx", ".css", ".coffee", ".json"],
    // extensions that are used

    alias: {
      cldr: "cldrjs",
      fs: "brfs",
    },
  },

  performance: {
    hints: "warning", // enum
    maxAssetSize: 200000, // int (in bytes),
    maxEntrypointSize: 400000, // int (in bytes)
    assetFilter: function(assetFilename) {
      // Function predicate that provides asset filenames
      return assetFilename.endsWith(".css") || assetFilename.endsWith(".js");
    }
  },

  // devtool: "source-map", // enum
  context: __dirname,
  target: "web",
  // externals: ["react"],

  devServer: {
    proxy: { // proxy URLs to backend development server
      "/api": "http://localhost:3000"
    },
    contentBase: path.join(__dirname, "dist"), // boolean | string | array, static file location
    compress: true, // enable gzip compression
    historyApiFallback: true, // true for index.html upon 404, object for multiple paths
    hot: false, // hot module replacement. Depends on HotModuleReplacementPlugin
    https: false, // true for self-signed, object for cert authority
    noInfo: true, // only errors & warns on hot reload
  },

  plugins: [
    new webpack.ContextReplacementPlugin(/moment[\/\\]locale$/, /en/),
    new HtmlWebpackPlugin({ template: "./src/index.html", inject: "body", excludeChunks: ["auth"], hash: !isDevelopment }),
    new HtmlWebpackPlugin({ template: "./src/auth.html", filename: "auth.html", excludeChunks: ["main"], inject: "body", hash: !isDevelopment }),
    new VersionFile({
      packageFile:path.join(__dirname, "package.json"),
      template: path.join(__dirname, "version.ejs"),
      outputFile: path.join(__dirname, "dist", "version.json")
    }),
    new webpack.DefinePlugin(
      Object.assign({
        process: {
          env: {
            NODE_ENV: JSON.stringify(process.env.NODE_ENV)
          }
        },
        VERSION: JSON.stringify(require("./package.json").version)
      }, getEnvVars(process.env.NODE_ENV))),
  ],

  resolveLoader: {},
  parallelism: 1,
  profile: true, // boolean
  bail: true,
  cache: false,
  watch: false,

  node: {
    console: false, // boolean | "mock"
    global: true, // boolean | "mock"
    process: true, // boolean
    __filename: "mock", // boolean | "mock"
    __dirname: "mock", // boolean | "mock"
    Buffer: true, // boolean | "mock"
    setImmediate: true // boolean | "mock" | "empty"
  },

  recordsPath: path.resolve(__dirname, "build/records.json"),
  recordsInputPath: path.resolve(__dirname, "build/records.json"),
  recordsOutputPath: path.resolve(__dirname, "build/records.json"),
}
