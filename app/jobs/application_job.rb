class ApplicationJob < ActiveJob::Base
  retry_on Timeout::Error, wait: :exponentially_longer, attempts: 5
end
