# frozen_string_literal: true

module Commands
  class UnknownCommand < Base
    private

    def handle
      send_message text: 'Command not found'
    end
  end
end
