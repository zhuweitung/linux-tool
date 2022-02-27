#!/bin/bash

sed -i 's/ExecStart=\/opt\/nezha\/agent\/nezha-agent -s \(.*\) -p \(.*\)/ExecStart=\/opt\/nezha\/agent\/nezha-agent -s \1 -p \2 --report-delay 3 --skip-conn --disable-command-execute/g' /etc/systemd/system/nezha-agent.service \
&& systemctl daemon-reload \
&& systemctl restart nezha-agent.service