const { ObjectId} = require('mongodb');
const mongoose = require('mongoose');
const JenisSchema = new mongoose.Schema({
  nama_jenis: {type:String, require: true},
});

const Item = mongoose.model('Jenis', JenisSchema);

module.exports = Item;