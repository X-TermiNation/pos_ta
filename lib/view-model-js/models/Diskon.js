const { ObjectId, Double, Int32 } = require('mongodb');
const mongoose = require('mongoose');

//schema barang
const BarangSchema = new mongoose.Schema({
  id_reference:{type:String , require:true},
  nama_barang: {type:String, require: true},
  jenis_barang: {type:String, require: true},
  kategori_barang: {type:String, require: true},
  harga_barang: {type: Number, require: true},
  Qty:{type:Number, require:true},
  exp_date:{type:Date},
});

//schema diskon
const DiskonSchema = new mongoose.Schema({
  nama_diskon: {type:String, require: true, unique:true},
  persentase_diskon:{type: Number, require: true},
  start_date: {type:Date, require: true},
  end_date: {type: Date, require: true},
  Barang:[BarangSchema]
});

const Item = mongoose.model('Diskon', DiskonSchema);
module.exports = Item;