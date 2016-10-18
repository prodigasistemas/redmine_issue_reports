#!/bin/bash

PGPASSWORD=redmine psql redmine -U redmine < postgresql_config.sql
