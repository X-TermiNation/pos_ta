const express = require('express')
const { Cabang } = require('../models/cabang')
const bodyParser = require('body-parser')
const router = express.Router()
const {
  insertCabang,
  searchCabangByName,
  searchCabangByID
} = require('../view_models_realm/realm_database')
router.use(bodyParser.json())

//
router.get('/caricabang/:namacabang', async (req, res) => {
  const { namacabang } = req.params
  try {
    let cabang = await searchCabangByName(namacabang)
    res.status(200).json({
      status: 200,
      data: cabang
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
    if (existingData) {
      return res.status(409).json({ message: 'The data already exists.' })
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
      let cabang2 = await Cabang.find()
      // Send the data to the client
      res.status(200).json({
        status: 200,
        data: cabang2,
        message: 'Data retrieved from the database'
      })

      // Store the data in Redis for future use
      redis.set('data_cabang', JSON.stringify(cabang2))
    }
  } catch (err) {
    console.log('Error Occurred' + err)
  }
})

module.exports = router
