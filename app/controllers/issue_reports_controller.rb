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

    @resolved_issues = issues_list('due_date', true)
    @resolved_details = ProdigaIssueReport.details(@resolved_issues)

    @unresolved_issues = issues_list('start_date', false)
    @unresolved_details = ProdigaIssueReport.details(@unresolved_issues)

    @config = ProdigaConfig.new

    render :index
  end

  private

  def issues_list(field, is_closed)
    ProdigaIssueReport.list(
      field,
      is_closed,
      @project.id,
      params[:issue_reports_start_date],
      params[:issue_reports_due_date]
    )
  end
end
