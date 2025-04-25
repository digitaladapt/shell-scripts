#!/usr/bin/env bash

sort <&0 | uniq --count | sort --numeric-sort

