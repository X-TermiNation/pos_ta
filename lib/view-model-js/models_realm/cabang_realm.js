const { List } = require('realm')

const SatuanSchema = {
  name: 'Satuan',
  embedded: true,
  properties: {
    _id: 'objectId',
    jumlah_satuan: 'int',
    nama_satuan: 'string'
  }
}

const BarangSchema = {
  name: 'Barang',
  embedded: true,
  properties: {
    _id: 'objectId',
    Qty: 'int',
    Satuan: { type: 'list', objectType: 'Satuan' },
    exp_date: { type: 'date', optional: true },
    harga_barang: 'int',
    jenis_barang: 'string',
    kategori_barang: 'string',
    nama_barang: 'string'
  }
}

const GudangSchema = {
  name: 'Gudang',
  embedded: true,
  properties: {
    _id: 'objectId',
    Barang: { type: 'list', objectType: 'Barang' },
    alamat: 'string'
  }
}

const UserSchema = {
  name: 'Users',
  embedded: true,
  properties: {
    _id: 'objectId',
    email: 'string',
    fname: 'string',
    lname: 'string',
    password: 'string',
    role: 'string'
  }
}

const CabangSchema = {
  name: 'Cabang',
  properties: {
    _id: 'objectId',
    Gudang: { type: 'list', objectType: 'Gudang' },
    Users: { type: 'list', objectType: 'Users' },
    __v: 'int?',
    alamat: 'string',
    nama_cabang: 'string',
    no_telp: 'string'
  },
  primaryKey: '_id'
}

module.exports = {
  SatuanSchema,
  BarangSchema,
  GudangSchema,
  UserSchema,
  CabangSchema
}
