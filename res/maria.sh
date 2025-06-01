#!/bin/bash

service mariadb start && \
    mariadb-secure-installation <<EOF

y
y
m
m
y
y
y
y
EOF