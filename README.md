# twocan
Twocan Politics

## Get started

Fill in credentials in a `.env` file or in your environment.

```bash
$ npm i
$ ./start.sh
$ ./psql.sh
$ ./stop.sh
```

## Download Bills (WIP)

Be sure to have `httpie` and `jq` installed via [Homebrew](https://brew.sh/) or another tool:
```bash
$ brew install httpie jq
```
...and then download away:

```bash
$ mkdir data && cd data
$ http --json https://www.govinfo.gov/bulkdata/json/BILLS/116/1/hr | jq '.files[] | select(.mimeType == "application/zip") | .link' | xargs http -d | tar xzf -
```
