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
    __v: 'int?',
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
        resolve(true)
      })
      .on('error', () => {
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
    //untuk hapus semua
    // realm.write(() => {
    //   realm.deleteAll()
    // })
    console.log('Realm initialized successfully!')
  } catch (error) {
    console.error('Error initializing Realm:', error)
    throw error
  } finally {
    //realm.close()
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

async function searchGudangById(cabangId) {
  const realm = await openRealm()
  try {
    const cabang = realm.objectForPrimaryKey('Cabang', cabangId)
    if (!cabang) {
      throw new Error('Cabang not found')
    }
    const GudangCabang = cabang.Gudang
    return GudangCabang
  } catch (error) {
    console.log('Error searching for users by email:', error)
    throw error
  } finally {
    // realm.close();
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
    // realm.subscriptions.update((subs) => {
    //   subs.add(realm.objects('Users'))
    // })
    realm.write(() => {
      cabang.Users.push({
        _id: new BSON.ObjectId(),
        email: userData.email,
        password: userData.password,
        fname: userData.fname,
        lname: userData.lname,
        role: userData.role
      }) // Add the new user data to the 'Users' array
    })
  } finally {
    realm.close()
  }
}
//show all user
async function showAllUserfromCabang(idcabang) {
  const realm = await openRealm()
  try {
    const cabang = realm.objectForPrimaryKey('Cabang', idcabang)
    if (!cabang) {
      throw new Error('Cabang not found')
    }
    return cabang.Users
  } catch (error) {
    console.log('error fetch all data cabang:' + error)
  } finally {
    //realm.close()
  }
}
//search user by email
async function searchUsersByEmail(cabangId, email) {
  const realm = await openRealm()
  try {
    const cabang = realm.objectForPrimaryKey('Cabang', cabangId)
    if (!cabang) {
      throw new Error('Cabang not found')
    }
    const usersCabang = cabang.Users.filtered('email == $0', email)
    return usersCabang
  } catch (error) {
    console.log('Error searching for users by email:', error)
    throw error
  } finally {
    // realm.close();
  }
}

//update user
async function updateUser(cabangId, userId, updatedUserData) {
  const realm = await openRealm()
  try {
    const cabang = realm.objectForPrimaryKey('Cabang', cabangId)
    if (!cabang) {
      throw console.log('Cabang not found')
    }
    const userIndex = cabang.Users.findIndex((user) => user._id.equals(userId))
    if (userIndex === -1) {
      throw console.log('User tidak ditemukan')
    }

    realm.write(() => {
      cabang.Users[userIndex].fname =
        updatedUserData.fname || cabang.Users[userIndex].fname
      cabang.Users[userIndex].lname =
        updatedUserData.lname || cabang.Users[userIndex].lname
      cabang.Users[userIndex].role =
        updatedUserData.role || cabang.Users[userIndex].role
    })

    console.log('User updated successfully')
    return Array.from(cabang.Users[userIndex])
  } catch (error) {
    console.error('Error updating user:', error)
    throw error
  } finally {
    realm.close()
  }
}
//delete user
async function deleteUser(cabangId, userId) {
  const realm = await openRealm()
  try {
    const cabang = realm.objectForPrimaryKey('Cabang', cabangId)
    if (!cabang) {
      throw new Error('Cabang not found')
    }

    const userIndex = cabang.Users.findIndex((user) => user._id.equals(userId))
    if (userIndex === -1) {
      throw new Error('User not found in cabang')
    }

    realm.write(() => {
      cabang.Users.splice(userIndex, 1)
    })
    console.log('User deleted successfully')
    return 'success'
  } catch (error) {
    console.error('Error deleting user:', error)
    throw error
  } finally {
    realm.close()
  }
}

//owner route
async function insertOwner(ownerData) {
  const realm = await openRealm()
  try {
    realm.subscriptions.update((subs) => {
      subs.add(realm.objects('Owner'))
    })
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

//barang
//get barang dari cabang
async function ShowItemFromCabang(id_cabang, id_gudang) {
  const realm = await openRealm()
  try {
    const cabang = realm.objectForPrimaryKey('Cabang', id_cabang)
    if (!cabang) {
      throw console.log('Cabang not found')
    }

    const gudang = cabang.Gudang
    if (!gudang) {
      throw console.log('Gudang not found in cabang')
    }

    // Access the barang array in the gudang
    const barang = gudang.Barang
    return barang
  } catch (error) {
    console.log('gagal ambil data barang')
  }
}
//add barang
async function AddItems(id_cabang, id_gudang, BarangData) {
  const realm = await openRealm()
  try {
    realm.write(() => {
      const cabang = realm.objectForPrimaryKey('Cabang', id_cabang)
      if (!cabang) {
        throw new Error('Cabang not found')
      }
      const gudang = cabang.Gudang
      if (!gudang) {
        throw new Error('Gudang not found in cabang')
      }

      gudang.Barang.push({
        _id: new BSON.ObjectId(),
        nama_barang: BarangData.nama_barang,
        jenis_barang: BarangData.jenis_barang,
        kategori_barang: BarangData.kategori_barang,
        harga_barang: BarangData.harga_barang,
        Qty: BarangData.Qty,
        exp_date: BarangData.exp_date
      })
      return BarangData
    })

    console.log('Barang added successfully')
  } catch (error) {
    console.error('Gagal Tambah barang:', error)
    throw error
  } finally {
    realm.close()
  }
}

//kategori
async function getallCategory() {
  let realm = await openRealm()
  try {
    const kategoriDataAll = realm.objects('kategori')
    return kategoriDataAll
  } catch (error) {
    console.log('error fetch all data kategori:' + error)
  }
}

async function getfirstkategori() {
  let realm = await openRealm()
  try {
    const kategoriDataAll = realm.objects('kategori')
    if (kategoriDataAll.length > 0) {
      return kategoriDataAll[0] // Return the first element
    } else {
      return null // Return null if no data is found
    }
  } catch (error) {
    console.log('Error fetching the first category data:', error)
    throw error
  } finally {
    //realm.close();
  }
}

async function SearchKategoriByName(datakategori) {
  let realm = await openRealm()
  try {
    const kategoriDataAll = realm
      .objects('kategori')
      .filtered('nama_kategori = $0', datakategori.nama_kategori)
    if (kategoriDataAll.length > 0) {
      return kategoriDataAll[0] // Return the first matching element
    } else {
      return null // Return null if no data is found
    }
  } catch (error) {
    console.log('Error fetching the first category data:', error)
    throw error
  } finally {
    //realm.close();
  }
}

async function addKategori(datakategori) {
  const realm = await openRealm()
  try {
    realm.subscriptions.update((subs) => {
      subs.add(realm.objects('kategori'))
    })
    realm.write(() => {
      realm.create('kategori', {
        _id: new BSON.ObjectId(),
        nama_kategori: datakategori.nama_kategori,
        id_jenis: Realm.BSON.ObjectId(datakategori.id_jenis)
      })
    })
    return datakategori
  } catch (error) {
    console.log('tidak berhasil menambah data!: ' + error)
  } finally {
    //realm.close()
  }
}

//jenis
async function getallJenis() {
  try {
    let realm = await openRealm()
    const jenisDataAll = realm.objects('Jenis')
    return jenisDataAll
  } catch (error) {
    console.log('error fetch all data jenis:' + error)
  }
}

async function getfirstJenis() {
  let realm = await openRealm()
  try {
    const jenisDataAll = realm.objects('Jenis')
    if (jenisDataAll.length > 0) {
      return jenisDataAll[0]
    } else {
      return null
    }
  } catch (error) {
    console.log('Error fetching the first Jenis data:', error)
    throw error
  } finally {
    //realm.close();
  }
}

async function SearchJenisByName(datajenis) {
  let realm = await openRealm()
  try {
    const jenisDataAll = realm
      .objects('kategori')
      .filtered('nama_kategori = $0', datajenis.nama_jenis)
    if (jenisDataAll.length > 0) {
      return jenisDataAll[0] // Return the first matching element
    } else {
      return null // Return null if no data is found
    }
  } catch (error) {
    console.log('Error fetching the first category data:', error)
    throw error
  } finally {
    //realm.close();
  }
}

async function addJenis(datajenis) {
  const realm = await openRealm()
  try {
    realm.subscriptions.update((subs) => {
      subs.add(realm.objects('Jenis'))
    })
    realm.write(() => {
      realm.create('Jenis', {
        _id: new BSON.ObjectId(),
        nama_jenis: datajenis.nama_jenis
      })
    })
    return datajenis
  } catch (error) {
    console.log('tidak berhasil menambah data!:' + error)
  } finally {
    //realm.close()
  }
}

async function searchjenisBykategori(katakategori) {
  let realm = await openRealm()
  try {
    const kategori = await realm
      .objects('Kategori')
      .filtered('nama_kategori == $0', katakategori)[0]
    if (!kategori) {
      console.log('kategori tidak ditemukan')
    } else {
      const jenis = realm.objectForPrimaryKey('Jenis', kategori.id_jenis)
      if (!jenis) {
        console.log('Jenis tidak ditemukan')
        return null
      } else {
        return jenis
      }
    }
  } catch (error) {
    console.log('gagal mendapat jenis dari kategori...')
  } finally {
    //realm.close()
  }
}

//diskon

module.exports = {
  AddItems,
  addKategori,
  addJenis,
  deleteUser,
  getallCategory,
  getfirstkategori,
  getfirstJenis,
  getallJenis,
  initializeRealm,
  insertCabang,
  insertGudang,
  insertOwner,
  insertUser,
  searchCabangByName,
  searchCabangByID,
  searchUsersByEmail,
  searchGudangById,
  searchjenisBykategori,
  showAllCabang,
  showAllUserfromCabang,
  ShowItemFromCabang,
  searchjenisBykategori,
  SearchJenisByName,
  SearchKategoriByName,
  SearchOwner,
  updateUser
}
