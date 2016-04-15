module IssueReportsHelper
  def percent_format(value, total)
    value > 0 ? (value.to_f / total.to_f * 100).round : 0
  end
end
