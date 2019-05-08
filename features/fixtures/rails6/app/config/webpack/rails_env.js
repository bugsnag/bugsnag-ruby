process.env.NODE_ENV = process.env.NODE_ENV || 'rails_env'

const environment = require('./environment')

module.exports = environment.toWebpackConfig()
