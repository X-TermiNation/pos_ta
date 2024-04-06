const express = require('express')
const app = express()
const cors = require('cors')
const bodyParser = require('body-parser')
const logger = require('morgan')
// const mongoose = require('mongoose')
const jwt = require('jsonwebtoken')
const Realm = require('realm')

const port = 3000
// const config = require('./config')

const UserRouter = require('./view-model-js/routes/user')
const BarangRouter = require('./view-model-js/routes/barang')
const CabangRouter = require('./view-model-js/routes/cabang')
const GudangRouter = require('./view-model-js/routes/gudang')

app.use(logger('dev'))
// const dbUrl = config.dbUrl

var options = {
  keepAlive: 1,
  connectTimeoutMS: 30000,
  useNewUrlParser: true,
  useUnifiedTopology: true
}

// mongoose.connect(dbUrl)
app.use(cors())
app.use(bodyParser.urlencoded({ extended: true }))
app.use(bodyParser.json())

const authRouter = require('./user_auth')
app.use('/auth', authRouter)
app.use('/user', UserRouter)
app.use('/barang', BarangRouter)
app.use('/cabang', CabangRouter)
app.use('/gudang', GudangRouter)
app.use('/auth', authRouter)

const {
  initializeRealm
} = require('./view-model-js/view_models_realm/realm_database')

initializeRealm()
  .then(() => {
    app.listen(port, function () {
      console.log('Runnning on ' + port)
    })
  })
  .catch((err) => {
    console.error('Failed to connect to Realm MongoDB:', err)
  })

module.exports = app
