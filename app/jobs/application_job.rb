class ApplicationJob < ActiveJob::Base
  retry_on Timeout::Error, wait: :polynomially_longer, attempts: 5
end
