class ProdigaConfig
  attr_accessor :locale, :severity_number, :severity_name, :status_suspended,
                :daily_hours, :inverval_hours, :break_time, :start_time,
                :closing_time

  def initialize
    @config_file = File.dirname(__FILE__) + "/../../config/config.yml"

    load
  end

  def load
    if File.exist?(@config_file)
      config = YAML.load_file(@config_file)

      if config
        @locale = config['locale']
        @severity_number = config['severity']['number']
        @severity_name = config['severity']['name']
        @status_suspended = config['status']['suspended']
        @daily_hours = config['hours']['daily'].hour_formatted
        @inverval_hours = config['hours']['interval'].hour_formatted
        @break_time = config['hours']['break_time'].hour_formatted
        @start_time = config['hours']['start_time'].hour_formatted
        @closing_time = config['hours']['closing_time'].hour_formatted
      end
    else
      raise Exception, "File config/config.yml not found! Read README.md file."
    end
  end
end

class Integer
  def hour_formatted
    hour = 0.0 if hour.to_s.blank?

    hour = self.to_f

    hour_array = hour.to_s.split('.')

    "%02d:%02d" % [hour_array[0].to_i, hour_array[1].to_i]
  end
end
