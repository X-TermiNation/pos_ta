const Realm = require('realm')
const BSON = Realm.BSON
const http = require('http')
const config = require('./config')
const realmId = 'posta-jctyi'

const LogInEmail = config.email
const LogInPassword = config.password
// Initialize Realm Sync with your Realm application ID
const apl = new Realm.App({
  id: realmId,
  baseFilePath: './local_storage.realm'
})
const {
  SatuanSchema,
  BarangSchema,
  GudangSchema,
  UserSchema,
  CabangSchema
} = require('../models_realm/cabang_realm')
const { DiskonSchema } = require('../models_realm/Diskon_realm')
const { Console } = require('console')
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

//check the internet
async function isOnline() {
  return new Promise((resolve) => {
    http
      .get('http://google.com', (res) => {
        // If request succeeds, resolve with true
        resolve(true)
      })
      .on('error', () => {
        // If request fails, resolve with false
        resolve(false)
      })
  })
}
async function LogInRealm(email, password) {
  try {
    const online = await isOnline()
    let user
    if (online) {
      // Log in with email and password
      user = await apl.logIn(Realm.Credentials.emailPassword(email, password))

      if (!user) {
        // Attempt to register a new user if login fails
        console.log('Attempting to register a new user...')
        await app.emailPasswordAuth.registerUser(email, password)
        console.log('Account registered!')

        // Log in the newly registered user
        user = await app.logIn(Realm.Credentials.emailPassword(email, password))
      }
      return user
    }
  } catch (error) {
    console.log('login problem:' + error)
  }
}

async function openRealm() {
  try {
    const user = await LogInRealm(LogInEmail, LogInPassword)
    const schema = [
      SatuanSchema,
      BarangSchema,
      GudangSchema,
      UserSchema,
      CabangSchema,
      DiskonSchema,
      JenisSchema,
      KategoriSchema,
      OwnerSchema
    ]

    return await Realm.open({
      path: './local_storage.realm',
      schema: schema,
      sync: {
        user: user,
        flexible: true
      }
    })
  } catch (error) {
    console.log('error open realm: ' + error)
  }
}

async function initializeRealm() {
  let realm = await openRealm()
  try {
    console.log('Realm initialized successfully!')
  } catch (error) {
    console.error('Error initializing Realm:', error)
    throw error
  } finally {
    realm.close()
  }
}

//cabang route
//insert cabang
async function insertCabang(cabangData) {
  const realm = await openRealm()
  try {
    realm.subscriptions.update((subs) => {
      subs.add(realm.objects('Cabang'))
    })
    realm.write(() => {
      realm.create('Cabang', {
        _id: new BSON.ObjectId(),
        alamat: cabangData.alamat,
        nama_cabang: cabangData.nama_cabang,
        no_telp: cabangData.no_telp
      })
    })
  } finally {
    realm.close()
  }
}
//cari cabang
async function showAllCabang() {
  const realm = await openRealm()
  try {
    const cabangDataAll = realm.objects('Cabang')
    return cabangDataAll
  } catch (error) {
    console.log('error fetch all data cabang:' + error)
  } finally {
    //realm.close()
  }
}

async function searchCabangByName(namacabang) {
  const realm = await openRealm()
  try {
    const cabang = realm
      .objects('Cabang')
      .filtered('nama_cabang == $0', namacabang)
    const cabangdata = Array.from(cabang)
    return cabangdata
  } catch (error) {
    console.error('Error searching for cabang:', error)
    throw error
  } finally {
    //realm.close()
  }
}
async function searchCabangByID(idcabang) {
  const realm = await openRealm()
  try {
    const cabang = realm.objectForPrimaryKey('Cabang', idcabang)
    return cabang
  } catch (error) {
    console.error('Error searching for cabang:', error)
    throw error
  } finally {
    //realm.close()
  }
}

//gudang route
async function insertGudang(cabangId, gudangData) {
  const realm = await openRealm()
  try {
    const cabang = realm.objectForPrimaryKey('Cabang', cabangId)
    if (!cabang) {
      throw new Error('Cabang not found')
    }
    // realm.subscriptions.update((subs) => {
    //   subs.add(realm.objects('Gudang'))
    // })
    realm.write(() => {
      cabang.Gudang.push({
        alamat: gudangData.alamat,
        _id: new BSON.ObjectId()
      })
    })
  } catch (error) {
    console.log('error insert gudang:' + error)
  } finally {
    //realm.close()
  }
}

//user route
async function insertUser(cabangId, userData) {
  const realm = await openRealm()
  try {
    const cabang = realm.objectForPrimaryKey('Cabang', cabangId)
    if (!cabang) {
      throw new Error('Cabang not found')
    }
    realm.subscriptions.update((subs) => {
      subs.add(realm.objects('Users'))
    })
    realm.write(() => {
      cabang.Users.push({ _id: new BSON.ObjectId(), userData }) // Add the new user data to the 'Users' array
    })
  } finally {
    realm.close()
  }
}

//owner route
async function insertOwner(ownerData) {
  const realm = await openRealm()
  try {
    await realm.write(() => {
      realm.create('Owner', {
        _id: new BSON.ObjectId(),
        email: ownerData.email,
        password: ownerData.password,
        fname: ownerData.fname,
        lname: ownerData.lname
      })
    })
  } finally {
    realm.close()
  }
}

async function SearchOwner() {
  const realm = await openRealm()
  try {
    await realm.subscriptions.update((subs) => {
      subs.add(realm.objects('Owner'))
    })
    const data = realm.objects('Owner')
    if (data.length > 0) {
      return realm.objects('Owner')
    } else {
      return console.log('data tidak ada')
    }
  } catch (error) {
    console.log('fetch data Owner failed: ' + error)
  } finally {
    //realm.close()
  }
}

module.exports = {
  initializeRealm,
  showAllCabang,
  insertUser,
  insertCabang,
  searchCabangByName,
  searchCabangByID,
  insertGudang,
  insertOwner,
  SearchOwner
}
