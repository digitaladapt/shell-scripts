#!/bin/bash
# speed-test-ttfb https://www.example.com/

curl -w "Connect time: %{time_connect} Time to first byte: %{time_starttransfer} Total time: %{time_total} \n" -s -o /dev/null "$@"

