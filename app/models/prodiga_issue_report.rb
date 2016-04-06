class ProdigaIssueReport < ActiveRecord::Base
  unloadable

  def self.summary(project_id)
    process_summary(project_id)
  end

  private

  def self.process_summary(project_id)
    occurrences = {}

    1.upto(5) do |severity|
      occurrences[severity] = {'resolved' => 0, 'unresolved' => 0}
    end

    results = get_summary(project_id)

    results.each do |result|
      if !result['severity'].blank?
        severity = result['severity'].to_i

        status = 'resolved'
        if result['status'] != 'Fechada'
          status = 'unresolved'
        end

        occurrences[severity][status] = occurrences[severity][status] + result['count'].to_i
      end
    end

    occurrences
  end

  def self.get_summary(project_id)
    Issue.connection.select_all("
      SELECT cv.value AS severity, ist.name AS status, count(*) AS count
      FROM issues AS i
      INNER JOIN issue_statuses AS ist ON (ist.id = i.status_id)
      INNER JOIN custom_values AS cv ON (cv.customized_id = i.id)
      INNER JOIN custom_fields AS cf ON (cf.id = cv.custom_field_id)
      WHERE i.project_id = #{project_id} AND cf.name = 'Grau de severidade'
      GROUP BY cv.value, ist.name
      ORDER BY cv.value
    ")
  end
end
