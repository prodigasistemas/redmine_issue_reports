require 'holidays/core_extensions/date'

class Date
  include Holidays::CoreExtensions::Date
end

class ProdigaIssueReport < ActiveRecord::Base
  unloadable

  def self.summary(project_id, start_date, due_date)
    process_summary(project_id, start_date, due_date)
  end

  def self.process_summary(project_id, start_date, due_date)
    occurrences = {}

    1.upto(5) do |severity|
      occurrences[severity] = {'resolved' => 0, 'unresolved' => 0}
    end

    {'start_date' => false, 'due_date' => true}.each do |filter, is_closed|
      results = get_summary(filter, is_closed, project_id, start_date, due_date)

      results.each do |result|
        severity = result['severity'].to_i

        status = is_closed ? 'resolved' : 'unresolved'

        occurrences[severity][status] = occurrences[severity][status] + result['count'].to_i
      end
    end

    occurrences
  end

  def self.get_summary(filter, is_closed, project_id, start_date, due_date)
    query = ActiveRecord::Base.sanitize_sql_array(
      ["SELECT cv.value AS severity, ist.name AS status, count(*) AS count
        FROM issues AS i
        INNER JOIN issue_statuses AS ist ON (ist.id = i.status_id)
        INNER JOIN custom_values AS cv ON (cv.customized_id = i.id)
        INNER JOIN custom_fields AS cf ON (cf.id = cv.custom_field_id)
        WHERE i.project_id = ? AND cf.name = 'Grau de severidade' AND
        i.#{filter} BETWEEN ? AND ? AND ist.is_closed = ? AND cv.value != ''
        GROUP BY cv.value, ist.name
        ORDER BY cv.value", project_id, start_date, due_date, is_closed])

    ActiveRecord::Base.connection.select_all(query)
  end

  def self.list(filter, is_closed, project_id, start_date, due_date)
    query = ActiveRecord::Base.sanitize_sql_array(
      ["SELECT i.*, cv.value AS severity, ist.name AS status
        FROM issues AS i
        INNER JOIN issue_statuses AS ist ON (ist.id = i.status_id)
        INNER JOIN custom_values AS cv ON (cv.customized_id = i.id)
        INNER JOIN custom_fields AS cf ON (cf.id = cv.custom_field_id)
        WHERE i.project_id = ? AND cf.name = 'Grau de severidade' AND
        i.#{filter} BETWEEN ? AND ? AND ist.is_closed = ? AND cv.value != ''
        ORDER BY cv.value, i.#{filter}",
        project_id, start_date, due_date, is_closed])
    Issue.find_by_sql(query)
  end

  def self.details(issues)
    issue_status, histories, hours = {}, {}, {}

    IssueStatus.all.each { |issue| issue_status[issue.id.to_s] = issue.name }

    issues.each do |issue|
      journals = issue.journals.joins(:details).includes(:details)
                      .where("journal_details.prop_key = 'status_id'")
                      .order(:created_on)
      if !journals.blank?
        details = ''
        suspended_starting_date = nil
        discount = 0.0

        time = hours_period(issue.created_on, journals.last.created_on)

        first_time = "#{issue.created_on.to_time.hour}.#{issue.created_on.to_time.min}".to_f

        last_time = "#{journals.last.created_on.to_time.hour}.#{journals.last.created_on.to_time.min}".to_f

        first_status = issue_status[journals.first.details.first.value]

        if issue.created_on.to_date == journals.last.created_on.to_date
          time = subtract_time(last_time, first_time)
          discount += 2.0 if first_time.to_i < 12
        else
          if first_time.to_i < 18
            if first_status.downcase == 'fechada'
              time = subtract_time(first_time, 8.0)
            else
              discount = sum_time(discount, subtract_time(18.0, first_time))
            end
          end

          discount = sum_time(discount, subtract_time(18.0, last_time)) if last_time.to_i < 18
          discount += 2.0 if last_time.to_i < 12
        end

        journals.each do |journal|
          journal.details.each do |detail|
            old_value = issue_status[detail.old_value]
            new_value = issue_status[detail.value]

            details += "#{format_time(journal.created_on)} - #{new_value}<br/>"

            suspended_starting_date = journal.created_on if new_value.downcase == 'suspensa'

            if old_value.downcase == 'suspensa' && !suspended_starting_date.nil?
              suspended_end_date = journal.created_on

              suspended_time = hours_period(suspended_starting_date, suspended_end_date)

              suspended_discount = 0.0

              suspended_first_time = "#{suspended_starting_date.to_time.hour}.#{suspended_starting_date.to_time.min}".to_f

              suspended_last_time = "#{suspended_end_date.to_time.hour}.#{suspended_end_date.to_time.min}".to_f

              if suspended_starting_date.to_date == suspended_end_date.to_date
                suspended_time = subtract_time(suspended_last_time, suspended_first_time)
                suspended_discount += 2.0 if suspended_first_time.to_i < 12
              else
                suspended_discount = sum_time(suspended_discount, subtract_time(18.0, suspended_first_time)) if suspended_first_time.to_i < 18
                suspended_discount = sum_time(suspended_discount, subtract_time(18.0, suspended_last_time)) if suspended_last_time.to_i < 18
                suspended_discount += 2.0 if suspended_last_time.to_i < 12
              end

              discount = sum_time(discount, subtract_time(suspended_time, suspended_discount))

              suspended_starting_date = nil
            end
          end

          histories[issue.id] = details
        end

        hours[issue.id] = subtract_time(time, discount)
      end
    end

    {hours: hours, histories: histories}
  end

  def self.hours_period(start_date, due_date)
    hours = 0.0
    (start_date.to_date..due_date.to_date).each do |date|
      hours += 8.0 if !date.saturday? && !date.sunday? && !date.holiday?(:br)
    end
    hours
  end

  def self.subtract_time(_minuend, _subtrahend)
    minuend = float_to_array(_minuend)
    subtrahend = float_to_array(_subtrahend)

    minuend[1] = minuend[1] * 10 if minuend[1] <= 5
    subtrahend[1] = subtrahend[1] * 10 if subtrahend[1] <= 5

    if minuend[1] < subtrahend[1]
      minuend[0] -= 1
      minuend[1] += 60
    end

    minutes = minuend[1] - subtrahend[1]

    hours = minuend[0] - subtrahend[0]

    "#{hours}.#{minutes}".to_f
  end

  def self.sum_time(value1, value2)
    value_a = float_to_array(value1)
    value_b = float_to_array(value2)

    value_a[1] = value_a[1] * 10 if value_a[1] <= 5
    value_b[1] = value_b[1] * 10 if value_b[1] <= 5

    minutes = value_a[1] + value_b[1]

    if minutes > 60
      value_a[0] += 1
      minutes = minutes - 60
    end

    hours = value_a[0] + value_b[0]

    "#{hours}.#{minutes}".to_f
  end

  def self.float_to_array(value)
    result = value.to_s.split('.')

    0.upto(1) {|i| result[i] = result[i].to_i}

    result
  end
end
