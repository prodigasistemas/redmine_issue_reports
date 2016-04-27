class TaskUpdateIssues
  def self.run
    Issue.all.each do |issue|
      fields = CustomField.where("name IN('Criticidade', 'Complexidade', 'Grau de severidade')").pluck(:id, :name, :default_value)

      fields.each do |field|
        record = CustomValue.find_by(customized_type: 'Issue', customized_id: issue.id, custom_field_id: field[0])

        if record.nil?
          CustomValue.create(customized_type: 'Issue', customized_id: issue.id, custom_field_id: field[0], value: field[2])
        end
      end

      statuses_closed = IssueStatus.where(is_closed: true).pluck(:id)

      if issue.due_date.blank? && statuses_closed.include?(issue.status_id)
        temp_issue = Issue.find issue.id
        temp_issue.update(due_date: temp_issue.closed_on.to_date)
      end
    end
  end
end