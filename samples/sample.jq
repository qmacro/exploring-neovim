#!/usr/bin/env jq

.value |= (
    group_by(.ShippedDate[:4])
    | map(.[:2])
    | flatten
  )
