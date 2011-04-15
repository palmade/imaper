module Palmade::Imaper
  module Commands
    autoload :BaseCommand, File.join(IMAPER_LIB_DIR, 'imaper/commands/base_command')
    autoload :ListCommand, File.join(IMAPER_LIB_DIR, 'imaper/commands/list_command')
    autoload :MarkCommand, File.join(IMAPER_LIB_DIR, 'imaper/commands/mark_command')
    autoload :ArchiveCommand, File.join(IMAPER_LIB_DIR, 'imaper/commands/archive_command')
    autoload :AutoArchiveCommand, File.join(IMAPER_LIB_DIR, 'imaper/commands/auto_archive_command')
    autoload :ListmbCommand, File.join(IMAPER_LIB_DIR, 'imaper/commands/listmb_command')
    autoload :ShowCommand, File.join(IMAPER_LIB_DIR, 'imaper/commands/show_command')
  end
end
