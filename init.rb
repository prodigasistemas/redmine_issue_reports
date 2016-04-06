Redmine::Plugin.register :redmine_issue_reports do
  name 'Redmine Issue Reports plugin'
  author 'Luiz Sanches'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/prodigasistemas/redmine_issue_reports'
  author_url 'https://github.com/luizsanches'

  project_module :issue_reports do
    permission :index_reports, :issue_reports => :index
  end

  menu :project_menu,
     :issue_reports,
     { :controller => 'issue_reports', :action => 'index' },
     :param => :project_id,
     :before => :settings
end
