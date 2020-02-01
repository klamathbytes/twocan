const axios = require('axios')
const cheerio = require('cheerio')

// async function parse() {
//   const { data } = await axios.get('https://www.congress.gov/help/field-values/member-bioguide-ids')
//   const $ = cheerio.load(data)
//   const members = $('main table tr')
//     .map((i, el) => ({
//       name: $(el).find('td:first-child').text().trim(),
//       id: $(el).find('td:last-child').text().trim(),
//     }))
//     .get()
//     .filter(({ id }) => !!id)
//     .map(({ name, id }) => {
//       const [_, fullName, partyAndState] = name.match(/(.+)(\(.+\))/)
//       const [familyName, givenName, additionalName] = fullName.trim().split(' ').map(el => el.replace(/(,|\.)/g, '').trim())
//       return {
//         id,
//         familyName,
//         givenName,
//         additionalName: additionalName || '',
//       }
//     })
//
//   return members
// }

async function parseLinks() {
  const { data } = await axios.get('https://www.congress.gov/members')
  const $ = cheerio.load(data)
  const getLinks = (section) => $(`#members-${section} option`)
    .map((i, el) => {
      const url = $(el).attr('value')
      return {
        id: url.split('/').pop(),
        url,
      }
    })
    .get()
    .filter(link => link.url.startsWith('http'))
    .reduce((links, link) => ({
      ...links,
      [link.id]: link.url,
    }), {})
  const houseLinks = getLinks('representatives')
  const senateLinks = getLinks('senators')
  return { ...houseLinks, ...senateLinks }
}

async function parse() {
  const memberLinks = await parseLinks()
  const { data } = await axios.get('http://clerk.house.gov/xml/lists/MemberData.xml')
  const $ = cheerio.load(data, {
    normalizeWhitespace: true,
    xmlMode: true
  })
  const members = $('member').map((i, el) => {
    const name = $(el).find('sort-name').text()
    const bioguideID = $(el).find('bioguideID').text()
    if (!bioguideID) {
      const name = $(el).find('pred-sort-name').text()
      const bioguideID = $(el).find('pred-memindex').text()
      const [last, first] = name.split(',')
      return {
        name,
        bioguideID,
        url: memberLinks[bioguideID] || `https://www.congress.gov/member/${first.toLowerCase()}-${last.toLowerCase()}/${bioguideID}`,
        predecessor: true,
      }
    }
    return {
      name,
      bioguideID,
      url: memberLinks[bioguideID],
    }
  }).get()
  return members
}

module.exports = parse
