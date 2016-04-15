module IssueReportsHelper
  def format_hour(hour)
    hour = 0.0 if hour.to_s.blank?

    hour_array = hour.to_s.split('.')

    "%02d:%02d" % [hour_array[0].to_i, hour_array[1].to_i]
  end
end
