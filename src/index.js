require('dotenv').config()
const parse = require('./parse')
const db = require('./db')

function insert(members) {
  const text = 'INSERT INTO raw(raw_data) VALUES($1)'
  return db.query({ text, values: [members] })
}

parse().then(insert)
