# Redmine Issue Reports Plugin

## Installing a plugin

1. Copy plugin directory into #{RAILS_ROOT}/plugins.
If you are downloading the plugin directly from GitHub,
you can do so by changing into your plugin directory and issuing a command like

        git clone git://github.com/prodigasistemas/redmine_issue_reports.git

2. Put in your #{RAILS_ROOT}/Gemfile.local
3. 
        gem 'holidays'

3. Update your gems
4. 
        bundle install

4. Copy config file
5. 
        cd #{RAILS_ROOT}/plugins/redmine_issue_reports

        cp config/config.example.yml config/config.yml

5. Restart Redmine

6. Go to one of your project settings. Click on the Modules tab.
You should see the "Issue reports" module at the end of the modules list.
Enable plugin at project level. Now you will see "Issue report" tab at the project menu.
