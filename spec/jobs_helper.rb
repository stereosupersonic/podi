require "rails_helper"

module JobHelpers
  def reset_enqueued_jobs
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  def perform_enqueued_jobs_now!
    ActiveJob::Base.queue_adapter.enqueued_jobs.each do |job_data|
      ActiveJob::Base.execute(job_data)
    end
  end
end

RSpec.configure do |config|
  config.include JobHelpers
  config.include ActiveJob::TestHelper
  config.before { reset_enqueued_jobs }
end
