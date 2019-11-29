# frozen_string_literal: true

module Commands
  class Start < Base
    private

    def handle
      send_message text: "Let's get it started!"
    end
  end
end
