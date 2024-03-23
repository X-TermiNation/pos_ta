const { ObjectId } = require('mongodb');
const mongoose = require('mongoose');

//schema owner
const OwnerSchema = new mongoose.Schema({
    email: {type:String, require: true, unique:true},
    password: {type:String, require: true},
    fname: {type:String, require: true},
    lname: {type:String, require: true},
});

const item = mongoose.model('Owner', OwnerSchema);

module.exports = item ;