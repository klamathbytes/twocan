require('dotenv').config()
const parse = require('./parse')
const db = require('./db')

parse().then(data => {
  const text = 'INSERT INTO individual(bio_id, given_name, additional_name, family_name) VALUES($1, $2, $3, $4)'
  const members = data.map(({ id, givenName, additionalName, familyName }) => [id, givenName, additionalName, familyName])
  return Promise.all(members.map(member => db.query({ text, values: member })))
})
