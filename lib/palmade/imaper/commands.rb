module Palmade::Imaper
  module Commands
    autoload :BaseCommand, File.join(IMAPER_LIB_DIR, 'imaper/commands/base_command')
    autoload :ListCommand, File.join(IMAPER_LIB_DIR, 'imaper/commands/list_command')
    autoload :MarkCommand, File.join(IMAPER_LIB_DIR, 'imaper/commands/mark_command')
  end
end
