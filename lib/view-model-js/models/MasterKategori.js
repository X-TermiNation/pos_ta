const { ObjectId} = require('mongodb');
const mongoose = require('mongoose');

const KategoriSchema = new mongoose.Schema({
  nama_kategori: {type:String, require: true},
  id_jenis:{ type: mongoose.Schema.Types.ObjectId, ref: 'Jenis' },
});

const Item = mongoose.model('Kategori', KategoriSchema);

module.exports = Item;