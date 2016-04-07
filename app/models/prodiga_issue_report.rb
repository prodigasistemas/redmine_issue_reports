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
        if !result['severity'].blank?
          severity = result['severity'].to_i

          status = is_closed ? 'resolved' : 'unresolved'

          occurrences[severity][status] = occurrences[severity][status] + result['count'].to_i
        end
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
      i.#{filter} BETWEEN ? AND ? AND ist.is_closed = ?
      GROUP BY cv.value, ist.name
      ORDER BY cv.value", project_id, start_date, due_date, is_closed])

    ActiveRecord::Base.connection.select_all(query)
  end
end
