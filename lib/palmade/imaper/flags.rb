module Palmade::Imaper
  class Flags
    DEFAULT_FLAG_SET = {
      :seen => 'Seen',
      :parsed => 'Parsed'
    }

    def initialize(conn, set = { })
      @conn = conn
      @set = DEFAULT_FLAG_SET.merge(set)
    end

    def get_flag(fk)
      @set[fk]
    end

    def [](fk)
      get_flag(fk)
    end
  end
end
