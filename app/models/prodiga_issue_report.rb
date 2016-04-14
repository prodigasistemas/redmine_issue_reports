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
        time = hours_period(issue.created_on, journals.last.created_on)

        first_hour = issue.created_on.to_time.hour

        last_hour = journals.last.created_on.to_time.hour

        first_status = issue_status[journals.first.details.first.value]

        if issue.created_on.to_date == journals.last.created_on.to_date
          calc = last_hour - first_hour
          calc -= 2 if first_hour < 12
          time = calc > 0 ? calc : 1
        else
          if first_hour < 18
            if first_status.downcase == 'fechada'
              time = first_hour - 8
            else
              time -= 18 - first_hour
            end
          end
        end

        if issue.created_on.to_date != journals.last.created_on.to_date
          time -= 18 - last_hour if last_hour < 18
          time -= 2 if last_hour < 12
        end

        details = ''
        suspended_starting_date = nil
        discount = 0

        journals.each do |journal|
          journal.details.each do |detail|
            old_value = issue_status[detail.old_value]
            new_value = issue_status[detail.value]

            details += "#{format_time(journal.created_on)} - #{new_value}<br/>"

            suspended_starting_date = journal.created_on if new_value.downcase == 'suspensa'

            if old_value.downcase == 'suspensa' && !suspended_starting_date.nil?
              suspended_end_date = journal.created_on

              discount = hours_period(suspended_starting_date, suspended_end_date)

              suspended_starting_date = nil
            end
          end

          histories[issue.id] = details
        end

        hours[issue.id] = time - discount
      end
    end

    {hours: hours, histories: histories}
  end

  def self.hours_period(start_date, due_date)
    hours = 0
    (start_date.to_date..due_date.to_date).each do |date|
      if !date.saturday? && !date.sunday? && !date.holiday?(:br)
        hours += 8
      end
    end
    hours
  end
end
