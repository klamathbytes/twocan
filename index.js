const axios = require('axios');
const cheerio = require('cheerio');

async function parse() {
  const { data } = await axios.get('https://www.congress.gov/help/field-values/member-bioguide-ids');
  const $ = cheerio.load(data);
  const members = $('main table tr')
    .map((i, el) => ({
      name: $(el).find('td:first-child').text().trim(),
      id: $(el).find('td:last-child').text().trim(),
    }))
    .get()
    .filter(({ id }) => !!id)
    .map(({ name, id }) => {
      const [_, fullName, partyAndState] = name.match(/(.+)(\(.+\))/);
      const [party, state] = partyAndState.replace(/[()]/g, '').split('-').map(el => el.trim());
      const [familyName, givenName, middleName] = fullName.trim().split(' ').map(el => el.replace(/(,|\.)/g, '').trim())
      return {
        id,
        familyName,
        givenName,
        middleName: middleName || '',
        party,
        state,
      };
    });

  console.log(JSON.stringify(members, null, 2))
}

(async () => {
  try {
    parse();
  } catch (e) {

  }
})();
