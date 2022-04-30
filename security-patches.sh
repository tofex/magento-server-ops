#!/bin/bash -e

apt list --upgradable 2>&1 | grep "\-security"
