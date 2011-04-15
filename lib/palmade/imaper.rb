IMAPER_LIB_DIR = File.expand_path(File.dirname(__FILE__))
IMAPER_ROOT_DIR = File.expand_path('../..', IMAPER_LIB_DIR)

module Palmade
  module Imaper
    autoload :Cli, File.join(IMAPER_LIB_DIR, 'imaper/cli')
    autoload :Conn, File.join(IMAPER_LIB_DIR, 'imaper/conn')
    autoload :Flags, File.join(IMAPER_LIB_DIR, 'imaper/flags')
    autoload :Message, File.join(IMAPER_LIB_DIR, 'imaper/message')
    autoload :Config, File.join(IMAPER_LIB_DIR, 'imaper/config')
    autoload :Commands, File.join(IMAPER_LIB_DIR, 'imaper/commands')
    autoload :Error, File.join(IMAPER_LIB_DIR, 'imaper/error')
  end
end
