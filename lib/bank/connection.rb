require 'fileutils'

module Bank
  class Connection
    def config(env = "development")
      @config ||= _read_config[env]
    end

  private

    def _read_config
      JSON.parse(
        IO.read(File.join(FileUtils.pwd, "db", "config.json"))
      )
    end
  end
end
