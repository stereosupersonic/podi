const { environment } = require('@rails/webpacker')
const webpack = require('webpack')
const CopyPlugin = require("copy-webpack-plugin");

environment.plugins.append('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
  'window.jQuery': 'jquery',
  Popper: ['popper.js', 'default']
}))

environment.plugins.append('CopyPlugin', new CopyPlugin({
  patterns: [{
    from: "node_modules/@podlove/web-player",
    to: "media/player"
  }],
}))

module.exports = environment
