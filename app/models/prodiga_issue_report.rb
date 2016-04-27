require 'holidays/core_extensions/date'

class Date
  include Holidays::CoreExtensions::Date
end

class ProdigaIssueReport < ActiveRecord::Base
  unloadable

  @@config = ProdigaConfig.new

  def self.summary(project_id, start_date, due_date, tracker_id)
    process_summary(project_id, start_date, due_date, tracker_id)
  end

  def self.process_summary(project_id, start_date, due_date, tracker_id)
    occurrences = {}

    1.upto(@@config.severity_number.to_i) do |severity|
      occurrences[severity] = {'resolved' => 0, 'unresolved' => 0}
    end

    {'start_date' => false, 'due_date' => true}.each do |filter, is_closed|
      results = get_summary(filter, is_closed, project_id, start_date, due_date, tracker_id)

      results.each do |result|
        severity = result['severity'].to_i

        status = is_closed ? 'resolved' : 'unresolved'

        occurrences[severity][status] = occurrences[severity][status] + result['count'].to_i
      end
    end

    occurrences
  end

  def self.get_summary(filter, is_closed, project_id, start_date, due_date, tracker_id)
    tracker = tracker_id.blank? ? '!=' : '='
    tracker_id = 0 if tracker_id.blank?

    query = ActiveRecord::Base.sanitize_sql_array(
      ["SELECT cv.value AS severity, ist.name AS status, count(*) AS count
        FROM issues AS i
        INNER JOIN issue_statuses AS ist ON (ist.id = i.status_id)
        INNER JOIN custom_values AS cv ON (cv.customized_id = i.id)
        INNER JOIN custom_fields AS cf ON (cf.id = cv.custom_field_id)
        INNER JOIN trackers AS tra ON (tra.id = i.tracker_id)
        WHERE i.project_id = ? AND cf.name = '#{@@config.severity_name}' AND
        i.#{filter} BETWEEN ? AND ? AND ist.is_closed = ? AND cv.value != '' AND
        tra.id #{tracker} ?
        GROUP BY cv.value, ist.name
        ORDER BY cv.value", project_id, start_date, due_date, is_closed, tracker_id])

    ActiveRecord::Base.connection.select_all(query)
  end

  def self.list(filter, is_closed, project_id, start_date, due_date, tracker_id)
    tracker = tracker_id.blank? ? '!=' : '='
    tracker_id = 0 if tracker_id.blank?

    query = ActiveRecord::Base.sanitize_sql_array(
      ["SELECT i.*, cv.value AS severity, ist.name AS status
        FROM issues AS i
        INNER JOIN issue_statuses AS ist ON (ist.id = i.status_id)
        INNER JOIN custom_values AS cv ON (cv.customized_id = i.id)
        INNER JOIN custom_fields AS cf ON (cf.id = cv.custom_field_id)
        INNER JOIN trackers AS tra ON (tra.id = i.tracker_id)
        WHERE i.project_id = ? AND cf.name = '#{@@config.severity_name}' AND
        i.#{filter} BETWEEN ? AND ? AND ist.is_closed = ? AND cv.value != '' AND
        tra.id #{tracker} ?
        ORDER BY cv.value, i.#{filter}",
        project_id, start_date, due_date, is_closed, tracker_id])
    Issue.find_by_sql(query)
  end

  def self.details(issues)
    issue_status, histories, hours, last_date = {}, {}, {}, {}
    issue_status_closed = status_closed(:id)

    IssueStatus.all.each { |issue| issue_status[issue.id.to_s] = issue.name }

    issues.each do |issue|
      journals = issue.journals.joins(:details).includes(:details)
                      .where("journal_details.prop_key = 'status_id'")
                      .order(:created_on)
      if !journals.blank?
        details = ''
        suspended_starting_date, date_closed = nil, nil

        journals.each do |journal|
          journal.details.each do |detail|
            if issue_status_closed.include?(detail.value.to_i)
              date_closed = journal.created_on
              break
            end
          end
          break unless date_closed.nil?
        end

        date_closed = journals.last.created_on if date_closed.nil?

        time = calculate_time(issue.created_on, date_closed)

        journals.each do |journal|
          journal.details.each do |detail|
            old_value = issue_status[detail.old_value]
            new_value = issue_status[detail.value]

            details += "#{format_time(journal.created_on)} - #{new_value}<br/>"

            suspended_starting_date = journal.created_on if new_value.downcase == @@config.status_suspended

            if old_value.downcase == @@config.status_suspended && !suspended_starting_date.nil?
              suspended_end_date = journal.created_on

              suspended_time = calculate_time(suspended_starting_date, suspended_end_date)

              time = subtract_time(time, suspended_time)

              suspended_starting_date = nil
            end
          end

          histories[issue.id] = details
        end

        hours[issue.id] = time

        last_date[issue.id] = date_closed
      end
    end

    {hours: hours, histories: histories, last_date: last_date}
  end

  def self.hours_period(start_date, due_date)
    hours = "00:00"
    (start_date.to_date..due_date.to_date).each do |date|
      if !date.saturday? && !date.sunday? && !date.holiday?(@@config.locale.to_sym)
        hours = sum_time(hours, @@config.daily_hours)
      end
    end
    hours
  end

  def self.subtract_time(_minuend, _subtrahend)
    minuend = _minuend.to_integer_array
    subtrahend = _subtrahend.to_integer_array

    if minuend[1] < subtrahend[1]
      minuend[0] -= 1
      minuend[1] += 60
    end

    minutes = minuend[1] - subtrahend[1]

    hours = minuend[0] - subtrahend[0]

    "%02d:%02d" % [hours, minutes]
  end

  def self.sum_time(value1, value2)
    value_a = value1.to_integer_array
    value_b = value2.to_integer_array

    minutes = value_a[1] + value_b[1]

    if minutes > 60
      value_a[0] += 1
      minutes = minutes - 60
    end

    hours = value_a[0] + value_b[0]

    "%02d:%02d" % [hours, minutes]
  end

  def self.calculate_time(first, last)
    time = hours_period(first, last)

    first_time = "%02d:%02d" % [first.to_time.hour, first.to_time.min]
    last_time  = "%02d:%02d" % [last.to_time.hour, last.to_time.min]

    if first.to_date == last.to_date
      time = subtract_time(last_time, first_time)

      time = subtract_time(time, @@config.inverval_hours) if first_time.to_i < @@config.break_time.to_i && time.to_i > @@config.inverval_hours.to_f
    else
      time = subtract_time(time, "16:00") if time.to_i >= 16

      time = sum_time(time, subtract_time(@@config.closing_time, first_time)) if first_time.to_i < @@config.closing_time.to_i

      time = subtract_time(time, @@config.inverval_hours) if first_time.to_i < @@config.break_time.to_i

      time = sum_time(time, subtract_time(last_time, @@config.start_time)) if last_time.to_i < @@config.closing_time.to_i

      time = subtract_time(time, @@config.inverval_hours) if last_time.to_i > @@config.break_time.to_i
    end

    time
  end

  def self.status_closed(field)
    IssueStatus.where(is_closed: true).pluck(field)
  end
end

class String
  def to_integer_array
    result = self.to_s.split(':')

    0.upto(1) {|i| result[i] = result[i].to_i}

    result
  end
end