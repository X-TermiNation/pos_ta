const express = require('express')
const { Cabang } = require('../models/cabang')
const bodyParser = require('body-parser')
const router = express.Router()
const Redis = require('ioredis')
const redis = new Redis()
const {
  insertGudang,
  searchCabangByName
} = require('../view_models_realm/realm_database')
router.use(bodyParser.json())

//
router.post('/tambahgudang/:idcabang/:nama_cabang', async (req, res) => {
  try {
    const idcabang = req.params.idcabang
    const nama_cabang = req.params.nama_cabang
    const cabang = await Cabang.findOne({ _id: idcabang })
    let gudang = req.body
    if (cabang.Gudang.length > 0) {
      return res.status(409).json({ message: 'The data already exists.' })
    } else {
      const datacabang_realm = await searchCabangByName(nama_cabang)
      const idcabang_realm = datacabang_realm._id
      console.log('Cabang ID realm:', idcabang_realm)
      await insertGudang(idcabang_realm, gudang)
      cabang.Gudang.push(gudang)
      await cabang.save()
      res.status(200).json({
        status: 200,
        data: gudang
      })
      redis.del('data_gudang', function (err, reply) {
        if (err) {
          console.error(err)
        } else {
          console.log(`Deleted key: data_gudang`)
        }
      })
      let gudang2 = await cabang.Gudang.find()
      // Send the data to the client
      res.status(200).json({
        status: 200,
        data: gudang2,
        message: 'Data retrieved from the database'
      })

      // Store the data in Redis for future use
      redis.set('data_gudang', JSON.stringify(gudang2))
    }
  } catch (err) {
    console.log('error occurred! :' + err)
  }
})

//
router.get('/:id_cabang', async (req, res, next) => {
  try {
    const cabang = await Cabang.findOne({
      _id: req.params.id_cabang
    })
    if (cabang) {
      // Only set the Content-Type header if we are sending a JSON response
      res.setHeader('Content-Type', 'application/json')
      let gudang = await cabang.Gudang
      res.status(200).json({
        status: 200,
        data: gudang
      })
    } else {
      res.status(400).json({
        status: 400,
        message: 'Gudang tidak Ditemukan!'
      })
    }
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message
    })
  }
  next()
})

module.exports = router
