#!/bin/bash

cp custom_fields.js ../../../public/javascripts

echo "<%= javascript_include_tag 'custom_fields' %>" >> ../../../app/views/issues/_form.html.erb

mysql -u redmine -predmine redmine < redmine_config.sql
