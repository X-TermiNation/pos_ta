const express = require('express')
const { Cabang } = require('../models/cabang')
const bodyParser = require('body-parser')
const router = express.Router()
const Redis = require('ioredis')
const redis = new Redis()
const {
  insertCabang,
  searchCabangByName,
  searchCabangByID,
  showAllCabang
} = require('../view_models_realm/realm_database')
router.use(bodyParser.json())

router.get('/showAllcabang', async (req, res) => {
  try {
    let cabang = await showAllCabang()
    res.status(200).json({
      status: 200,
      data: cabang
    })
  } catch (error) {
    console.log('data tidak ada')
    res.status(400).json({
      status: 400,
      message: err.message
    })
  }
})

//
router.get('/caricabang/:namacabang', async (req, res) => {
  const { namacabang } = req.params
  try {
    let cabang = await searchCabangByName(namacabang)
    let cabangArray = Array.from(cabang)
    res.status(200).json({
      status: 200,
      data: cabangArray
    })
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message
    })
  }
})

//
router.post('/tambahcabang', async (req, res) => {
  try {
    let cabang = req.body
    const existingData = await searchCabangByName(cabang.nama_cabang)
    if (existingData.length > 0) {
      return res.status(409).json(console.log('The data already exists.'))
    } else {
      await insertCabang(cabang)
      await res.status(200).json({
        status: 200,
        data: cabang
      })
      redis.del('data_cabang', function (err, reply) {
        if (err) {
          console.error(err)
        } else {
          console.log(`Deleted key: data_cabang`)
        }
      })
      let cabang2 = await showAllCabang()
      // Store the data in Redis for future use
      redis.set('data_cabang', JSON.stringify(cabang2))
    }
  } catch (err) {
    console.log('Error Insert Cabang:' + err)
  }
})

module.exports = router
