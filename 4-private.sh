#!/bin/sh

ip -4 addr list scope global | sed -n 's/.*inet \([0-9\.]\+\).*/\1/p' | head -n 1

#ip addr show | grep 'global' | grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1

