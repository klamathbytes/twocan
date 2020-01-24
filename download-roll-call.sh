#!/bin/bash

if [[ -d roll_call_lists ]]; then
  echo "roll_call_lists already exists"
  exit 1
fi

for congress in 114 115 116; do
  for session in 1 2; do
    roll_calls_url=https://www.senate.gov/legislative/LIS/roll_call_lists/vote_menu_${congress}_${session}.xml
    if curl -Is ${roll_calls_url} | head -n 1 | grep '200' ; then
      mkdir -p roll_call_lists/${congress}/${session}
      curl -s ${roll_calls_url} | xq . | jq '.vote_summary.votes.vote[].vote_number' -r | while read roll_call
      do
        name="${congress}_${session}_${roll_call}"
        echo "downloading ${name}..."
        roll_call_url=https://www.senate.gov/legislative/LIS/roll_call_votes/vote${congress}${session}/vote_${congress}_${session}_${roll_call}.xml
        curl -s ${roll_call_url} | xq . > roll_call_lists/${congress}/${session}/${name}.json
      done
    fi
  done
done
