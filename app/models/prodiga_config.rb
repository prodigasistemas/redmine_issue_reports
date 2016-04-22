class ProdigaConfig
  attr_accessor :locale, :severity_number, :severity_name, :status_suspended,
                :daily_hours, :inverval_hours, :break_time, :closing_time

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
        @daily_hours = config['hours']['daily']
        @inverval_hours = config['hours']['interval']
        @break_time = config['hours']['break_time']
        @closing_time = config['hours']['closing_time']
      end
    else
      raise Exception, "File config/config.yml not found! Read README.md file."
    end
  end
end
