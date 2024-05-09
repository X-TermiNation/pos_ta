const { ObjectId } = require('mongodb')
const mongoose = require('mongoose')
const Redis = require('ioredis')
const redis = new Redis()

//schema satuan
const SatuanSchema = new mongoose.Schema({
  nama_satuan: { type: String, require: true },
  jumlah_satuan: { type: Number, required: true }
})

//schema barang
const BarangSchema = new mongoose.Schema({
  nama_barang: { type: String, require: true },
  jenis_barang: { type: String, require: true },
  kategori_barang: { type: String, require: true },
  harga_barang: { type: Number, require: true },
  Qty: { type: Number, require: true },
  exp_date: { type: Date },
  Satuan: [SatuanSchema]
})

//schema gudang
const GudangSchema = new mongoose.Schema({
  alamat: { type: String, require: true },
  Barang: [BarangSchema]
})

//schema user
const UserSchema = new mongoose.Schema({
  email: { type: String, require: true, unique: true },
  password: { type: String, require: true },
  fname: { type: String, require: true },
  lname: { type: String, require: true },
  role: {
    type: String,
    require: true,
    enum: ['Manager', 'Kurir', 'Kasir', 'Admin Gudang']
  }
})

//schema cabang
const CabangSchema = new mongoose.Schema({
  nama_cabang: { type: String, require: true, unique: true },
  alamat: { type: String, require: true },
  no_telp: { type: String, require: true },
  Users: [UserSchema],
  Gudang: [GudangSchema]
})

const Satuan = mongoose.model('Satuan', SatuanSchema)
const Barang = mongoose.model('Barang', BarangSchema)
const Gudang = mongoose.model('Gudang', GudangSchema)
const Users = mongoose.model('Users', UserSchema)
const Cabang = mongoose.model('Cabang', CabangSchema)

module.exports = {
  Satuan,
  Barang,
  Gudang,
  Users,
  Cabang
}
