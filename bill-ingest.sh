#!/bin/bash
set -e
set -u
shopt -s nullglob

bills=""

bill_xml_to_json () {
  bills="$bills
\set content \`xq . \"$1\"\`
INSERT INTO public.raw (raw_data, raw_file) SELECT :'content'::jsonb, '$1';
"
  echo "$1"
}

#if arguments are greater than zero iterate over the supplied the xml files
#otherwise go thru all files.
if [[ $# -gt 0 ]]; then
  for f in "$@"; do bill_xml_to_json "$f"; done
else
  for f in *.xml; do bill_xml_to_json "$f"; done
fi

#runs all the bills from above in psql shell
echo "$bills" | psql
