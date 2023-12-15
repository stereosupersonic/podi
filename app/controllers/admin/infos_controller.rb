module Admin
  class InfosController < BaseController
    def show
    end

    def trigger_exception
      raise "This is a test exception from the Wartenberger Podcast"
    end
  end
end
