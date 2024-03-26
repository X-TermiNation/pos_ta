const Realm = require('realm')

const realmId = 'posta-jctyi'
// Initialize Realm Sync with your Realm application ID
const apl = new Realm.App({ id: realmId })
const {
  SatuanSchema,
  BarangSchema,
  GudangSchema,
  UserSchema,
  CabangSchema
} = require('../models_realm/cabang_realm')
const { DiskonSchema } = require('../models_realm/Diskon_realm')
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

//cabang route
async function insertCabang(cabangData) {
  const mongodb = apl.currentUser.mongoClient('mongodb-atlas')
  const cabangCollection = mongodb.db('Toko').collection('Cabang')
  await cabangCollection.insertOne(cabangData)
}

//gudang route
//masih blm bisa masuk
async function insertGudang(cabangId, gudangData) {
  const mongodb = apl.currentUser.mongoClient('mongodb-atlas')
  const cabangCollection = mongodb.db('Toko').collection('Cabang')
  await cabangCollection.updateOne(
    { _id: Realm.BSON.ObjectId(cabangId) },
    { $push: { Gudang: gudangData } }
  )
}

//user route
async function insertUser(cabangId, userData) {
  const mongodb = apl.currentUser.mongoClient('mongodb-atlas')
  const cabangCollection = mongodb.db('Toko').collection('Cabang')
  await cabangCollection.updateOne(
    { _id: Realm.BSON.ObjectId(cabangId) },
    { $push: { Users: userData } }
  )
}

//owner route
async function insertOwner(ownerData) {
  const mongodb = apl.currentUser.mongoClient('mongodb-atlas')
  const ownerCollection = mongodb.db('Toko').collection('Owner')
  await ownerCollection.insertOne(ownerData)
}

module.exports = {
  initializeRealm,
  insertUser,
  insertCabang,
  insertGudang,
  insertOwner
}
