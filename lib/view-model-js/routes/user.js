const express = require('express')
const { Cabang } = require('../models/cabang')
const Owner = require('../models/Owner')
const bodyParser = require('body-parser')
const router = express.Router()
const jwt = require('jsonwebtoken')
router.use(bodyParser.json())
const secretKey = 'PosTa'
const Redis = require('ioredis')
const redis = new Redis()

const checkResponseSentMiddleware = (req, res, next) => {
  if (res.headersSent) {
    // The response has been sent, so do nothing
    return
  }

  // The response has not been sent, so call the next middleware function
  next()
}
router.use(checkResponseSentMiddleware)

var signcode = 0

//buat add admin
const { insertOwner } = require('../view_models_realm/realm_database')
router.post('/addOwner', async (req, res) => {
  try {
    let owner = req.body
    let newOwner = new Owner(owner)
    await newOwner.save()
    await insertOwner(owner)
    res.status(200).json({
      status: 200,
      data: owner
    })
    redis.del('owner', function (err, reply) {
      if (err) {
        console.error(err)
      } else {
        console.log(`Deleted key: owner`)
      }
    })

    redis.set('owner', JSON.stringify(owner))
  } catch (err) {
    console.log('error insert data:' + err)
  }
})

router.post('/loginkasir', async (req, res) => {
  const { email, password } = req.body
  const user = await User.find({ email: email })
  if (user.role == 'Kasir' || user.role == 'Owner') {
    if (!user || user.password !== password) {
      res.status(401).send('Invalid username or password')
      return
    } else {
      const userdata = {
        id: user.id,
        cabang_id: user.cabang_id
      }
      const token = jwt.sign({ userdata }, secretKey, { expiresIn: '24h' })
      res.status(200).send({
        token,
        signcode
      })
    }
  } else {
    return res.status(401).send({ error: 'Unauthorized' })
  }
})

//
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body
    let userCabangId = null
    let Userrole = null
    const cabangs = await Cabang.find()

    for (const cabang of cabangs) {
      const user = cabang.Users.find((user) => user.email === email)
      if (user) {
        if (user.password === password) {
          userCabangId = cabang._id
          Userrole = user.role
          break
        } else {
          return res.status(401).json({ message: 'Invalid password' })
        }
      }
    }

    if (!userCabangId) {
      return res.status(404).json({ message: 'User not found' })
    }

    var signcode = 0
    if (Userrole == 'Manager') {
      signcode = 1
    } else if (Userrole == 'Admin Gudang') {
      signcode = 2
    }
    const token = jwt.sign({ userCabangId }, secretKey, { expiresIn: '24h' })
    res.status(200).send({
      token,
      signcode,
      userCabangId
    })
  } catch (error) {
    console.log('error occured:' + error)
  }
})

router.post('/verify', (req, res) => {
  const token = req.headers.token
  jwt.verify(token, secretKey, (err, decoded) => {
    if (err) {
      return res.status(401).send({ error: 'Unauthorized' })
    }
    res.send({ message: 'Selamat Datang!' })
  })
})

router.get('/owner', async (req, res, next) => {
  try {
    let owner = await Owner.findOne()
    if (owner) {
      res.setHeader('Content-Type', 'application/json')
      res.status(200).json({
        status: 200,
        data: owner
      })
    } else {
      res.status(400).json({
        status: 400,
        message: 'No User found'
      })
    }
  } catch (err) {
    console.log('Error occurred:', err)
    next(err)
  }
})

//tampilin semuanya
// router.get("/list", async (req, res) => {
//   // Only set the Content-Type header if the client accepts JSON
//   if (res.req.accepts('application/json')) {
//     res.setHeader('Content-Type', 'application/json');
//   }

//   try {
//     const cachedData = await redis.get('data_user');
//     if (!cachedData) {
//       // If data is not in Redis, query the database
//       let users = await User.find();
//       res.status(200).json({
//         status: 200,
//         data: users,
//       });
//       // Store the data in Redis for future use
//       redis.set('data_user', JSON.stringify(users));
//       console.log("ini kosong redis");
//     } else {
//       // If data exists in Redis, send the cached data
//       res.status(200).json({
//         status: 200,
//         data: JSON.parse(cachedData),
//         message: "Data retrieved from Redis cache",
//       });
//       console.log("ini berisi redis");
//     }
//   } catch (err) {
//     res.status(400).json({
//       status: 400,
//       message: err.message,
//     });
//   }
// });

//
router.get('/list/:id_cabang', async (req, res) => {
  const { id_cabang } = req.params
  if (res.req.accepts('application/json')) {
    res.setHeader('Content-Type', 'application/json')
  }

  try {
    const cachedData = await redis.get('data_user_' + id_cabang)
    if (!cachedData) {
      // If data is not in Redis, query the database
      let cabang = await Cabang.findOne({ _id: id_cabang })
      const users = cabang.Users
      res.status(200).json({
        status: 200,
        data: users
      })
      // Store the data in Redis for future use
      redis.set('data_user_' + id_cabang, JSON.stringify(users))
      console.log('ini kosong redis')
    } else {
      // If data exists in Redis, send the cached data
      res.status(200).json({
        status: 200,
        data: JSON.parse(cachedData),
        message: 'Data retrieved from Redis cache'
      })
      console.log('ini berisi redis')
    }
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message
    })
  }
})

//
router.put('/updateuser/:userId/:cabangId', async (req, res) => {
  try {
    if (res.req.accepts('application/json')) {
      res.setHeader('Content-Type', 'application/json')
    }
    let cabang = await Cabang.findById(req.params.cabangId)
    if (!cabang) {
      res.status(404).send('Cabang Tidak Ditemukan!')
    }
    let user = await cabang.Users.id(req.params.userId)
    Object.assign(user, req.body)
    await cabang.save()
    let updateduser = await cabang.Users.id(req.params.userId)
    if (user) {
      res.status(200).json({
        status: 200,
        data: updateduser
      })
      redis.del('data_user_' + req.params.cabangId, function (err) {
        if (err) {
          console.error(err)
        } else {
          console.log(`Deleted key: data_user_` + req.params.cabangId)
        }
      })
    } else {
      res.status(404).json({
        status: 404,
        message: 'No User found'
      })
    }
  } catch (err) {
    console.log('something went wrong:' + err)
  }
})

//
router.delete('/deleteuser/:id/:id_cabang', async (req, res) => {
  try {
    const { id, id_cabang } = req.params
    let cabang = await Cabang.findById(id_cabang)
    if (!cabang) {
      return res.status(401).send('Cabang Tidak Ditemukan!')
    }

    const user = cabang.Users.id(id)
    console.log(user)
    if (!user) {
      return res
        .status(404)
        .json({ message: 'User tidak ditemukan pada Cabang!' })
    }
    cabang.Users.pull(id)
    await cabang.save()
    redis.del('data_user_' + id_cabang, function (err, reply) {
      if (err) {
        console.error(err)
      } else {
        console.log(`Deleted key: data_user_` + id_cabang)
      }
    })
    if (user) {
      res.status(200).json({
        status: 200,
        message: 'User deleted successfully'
      })
    } else {
      res.status(404).json({
        status: 404,
        message: 'No User found'
      })
    }
  } catch (err) {
    res.status(400).json({
      status: 400,
      message: err.message
    })
  }
})

//
const {
  insertUser,
  searchCabangByName
} = require('../view_models_realm/realm_database')
router.post('/addUser/:id_cabang', async (req, res) => {
  const { id_cabang } = req.params
  try {
    if (res.req.accepts('application/json')) {
      res.setHeader('Content-Type', 'application/json')
    }
    const cabang = await Cabang.findOne({ _id: id_cabang })
    const nama_cabang = cabang.nama_cabang.toString()
    console.log('nama cabang add user:' + nama_cabang)
    if (cabang.length === 0) {
      return res.status(404).json({ message: 'Cabang tidak ditemukan' })
    }
    let user = req.body
    redis.del('data_user_' + id_cabang, function (err, reply) {
      if (err) {
        console.error(err)
      } else {
        console.log(`Deleted key: data_user_` + id_cabang)
      }
    })
    const existingUser = cabang.Users.find(
      (users) => users.email === user.email
    )
    if (existingUser) {
      return res.status(400).json({ message: 'Email sudah ada!' })
    } else {
      const datacabang = await searchCabangByName(nama_cabang)
      const idcabangrealm = datacabang._id
      console.log('id cabang realm:' + idcabangrealm)
      await insertUser(idcabangrealm, user)
      cabang.Users.push(user)
      await cabang.save()
      res.status(200).json({
        status: 200,
        data: user
      })
      let user2 = await cabang.Users
      redis.set('data_user_' + id_cabang, JSON.stringify(user2))
      // Send the data to the client
      res.status(200).json({
        status: 200,
        data: user2,
        message: 'Data retrieved from the database'
      })
    }
  } catch (err) {
    console.log('error insert data:' + err)
  }
})

//salah
router.get('/cariUserbyEmail/:id_cabang/:email', async (req, res, next) => {
  try {
    let cabang = await Cabang.findById(req.params.id_cabang)
    if (!cabang) {
      return res.status(404).json({
        status: 404,
        message: 'Cabang not found'
      })
    }
    let user = cabang.Users.find((user) => user.email === req.params.email)
    if (user) {
      // Only set the Content-Type header if we are sending a JSON response
      res.setHeader('Content-Type', 'application/json')

      return res.status(200).json({
        status: 200,
        data: user
      })
    } else {
      return res.status(400).json({
        status: 400,
        message: 'No User found with the specified email'
      })
    }
  } catch (err) {
    return res.status(500).json({
      status: 500,
      message: err.message
    })
  }
})

module.exports = router
