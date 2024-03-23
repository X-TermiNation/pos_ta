const express = require('express')
const app = express()
const cors = require('cors')
const bodyParser = require('body-parser')
const logger = require('morgan')
const mongoose = require('mongoose')
const jwt = require('jsonwebtoken')
const Realm = require('realm')

const realmId = 'posta-jctyi'
// Initialize Realm Sync with your Realm application ID
const apl = new Realm.App({ id: realmId })

const port = 3000
const config = require('./config')

const UserRouter = require('./view-model-js/routes/user')
const BarangRouter = require('./view-model-js/routes/barang')
const CabangRouter = require('./view-model-js/routes/cabang')
const GudangRouter = require('./view-model-js/routes/gudang')

const {
  SatuanSchema,
  BarangSchema,
  GudangSchema,
  UserSchema,
  CabangSchema
} = require('./view-model-js/models_realm/cabang_realm')
const { DiskonSchema } = require('./view-model-js/models_realm/Diskon_realm')
const JenisSchema = {
  name: 'Jenis',
  properties: {
    _id: 'objectId',
    __v: 'int',
    nama_jenis: 'string'
  },
  primaryKey: '_id'
}
const KategoriSchema = {
  name: 'kategori',
  properties: {
    _id: 'objectId',
    __v: 'int?',
    id_jenis: 'objectId',
    nama_kategori: 'string'
  },
  primaryKey: '_id'
}
const OwnerSchema = {
  name: 'Owner',
  properties: {
    _id: 'objectId',
    __v: 'int?',
    email: 'string',
    fname: 'string',
    lname: 'string',
    password: 'string'
  },
  primaryKey: '_id'
}

async function initializeRealm(email, password) {
  try {
    const user = await apl.logIn(
      Realm.Credentials.emailPassword(email, password)
    )

    if (!user) {
      // Attempt to register a new user if login fails
      console.log('Attempting to register a new user...')
      await apl.emailPasswordAuth.registerUser(email, password)
      console.log('Account registered!')

      // Log in the newly registered user
      user = await apl.logIn(Realm.Credentials.emailPassword(email, password))
    }

    const realm = await Realm.open({
      schema: [
        SatuanSchema,
        BarangSchema,
        GudangSchema,
        UserSchema,
        CabangSchema,
        DiskonSchema,
        JenisSchema,
        KategoriSchema,
        OwnerSchema
      ],
      sync: {
        user: user,
        flexible: true
      }
    })

    console.log('Realm initialized successfully!')
    return realm
  } catch (error) {
    console.error('Error initializing Realm:', error)
    throw error
  }
}

app.use(logger('dev'))
const dbUrl = config.dbUrl

var options = {
  keepAlive: 1,
  connectTimeoutMS: 30000,
  useNewUrlParser: true,
  useUnifiedTopology: true
}

mongoose.connect(dbUrl)
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
// ;(async () => {
//   try {
//     const realm = await initializeRealm(
//       'russelchandra.rc@gmail.com',
//       'kagamine2711'
//     )
app.listen(port, function () {
  console.log('Runnning on ' + port)
  console.log('tes')
})
//   } catch (error) {
//     console.error('Error initializing Realm:', error)
//   }
// })()

module.exports = app
