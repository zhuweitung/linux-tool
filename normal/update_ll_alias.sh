#!/bin/bash
sed -i "s/alias ll='ls -alF'/alias ll='ls -lF'/g" $HOME/.bashrc; \
source $HOME/.bashrc