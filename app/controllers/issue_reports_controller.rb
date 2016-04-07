class IssueReportsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id
  before_filter :authorize

  def index

  end

  def create
    @results = ProdigaIssueReport.summary(
      @project.id,
      params[:issue_reports_start_date],
      params[:issue_reports_due_date]
    )

    render :index
  end
end
