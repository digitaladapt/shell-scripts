#!/bin/bash

# works consistently if you specify the -6 to force IPv6
dig -6 +short AAAA myip.opendns.com @resolver1.opendns.com

