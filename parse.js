const axios = require('axios')
const cheerio = require('cheerio')

async function parse() {
  const { data } = await axios.get('https://www.congress.gov/help/field-values/member-bioguide-ids')
  const $ = cheerio.load(data)
  const members = $('main table tr')
    .map((i, el) => ({
      name: $(el).find('td:first-child').text().trim(),
      id: $(el).find('td:last-child').text().trim(),
    }))
    .get()
    .filter(({ id }) => !!id)
    .map(({ name, id }) => {
      const [_, fullName, partyAndState] = name.match(/(.+)(\(.+\))/)
      const [familyName, givenName, additionalName] = fullName.trim().split(' ').map(el => el.replace(/(,|\.)/g, '').trim())
      return {
        id,
        familyName,
        givenName,
        additionalName: additionalName || '',
      }
    })

  return members
}

module.exports = parse
