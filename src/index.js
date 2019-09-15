require('dotenv').config()
const parse = require('./parse')
const db = require('./db')

function insert(members) {
  const text = 'INSERT INTO individual(bio_id, data) VALUES($1, $2)'
  return Promise.all(members.map(member => db.query({ text, values: [member.id, member] })))
}

parse().then(insert)
