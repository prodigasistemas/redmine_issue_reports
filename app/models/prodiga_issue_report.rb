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
            if issue_status_closed.join(', ').include?(detail.value)
              date_closed = journal.created_on
              break
            end
          end
          break unless date_closed.nil?
        end

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

        hours[issue.id] = time.hour_formatted

        last_date[issue.id] = date_closed
      end
    end

    {hours: hours, histories: histories, last_date: last_date}
  end

  def self.hours_period(start_date, due_date)
    hours = 0.0
    (start_date.to_date..due_date.to_date).each do |date|
      if !date.saturday? && !date.sunday? && !date.holiday?(@@config.locale.to_sym)
        hours += @@config.daily_hours.to_f
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

    "#{hours}.#{minutes}".to_f
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

    "#{hours}.#{minutes}".to_f
  end

  def self.calculate_time(first, last)
    discount = 0.0
    time = hours_period(first, last)

    first_time = "#{first.to_time.hour}.#{first.to_time.min}".to_f
    last_time = "#{last.to_time.hour}.#{last.to_time.min}".to_f

    if first.to_date == last.to_date
      time = subtract_time(last_time, first_time)
      discount += @@config.inverval_hours.to_f if first_time.to_i < @@config.break_time.to_i && time > @@config.inverval_hours.to_f
    else
      if first_time.to_i < @@config.closing_time
        discount = sum_time(discount, subtract_time(@@config.closing_time.to_f, first_time))
      end

      discount = sum_time(discount, subtract_time(@@config.closing_time.to_f, last_time)) if last_time.to_i < @@config.closing_time.to_i
      discount += @@config.inverval_hours.to_f if last_time.to_i < @@config.break_time.to_i
    end

    subtract_time(time, discount)
  end

  def self.status_closed(field)
    IssueStatus.where(is_closed: true).pluck(field)
  end
end

class Float
  def hour_formatted
    hour = self

    hour = 0.0 if hour.to_s.blank?

    hour_array = hour.to_s.split('.')

    "%02d:%02d" % [hour_array[0].to_i, hour_array[1].to_i]
  end

  def to_integer_array
    result = self.to_s.split('.')

    0.upto(1) {|i| result[i] = result[i].to_i}

    result[1] = result[1] * 10 if result[1] <= 5

    result
  end
end
