class IssueReportsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id
  before_filter :authorize

  def index
    @results = ProdigaIssueReport.summary(@project.id)
  end

  def create
  end
end
