$stdout.sync = true

Rails.application.configure do
  # config.good_job.execution_mode = :external
  # config.good_job.enable_cron = true
  # config.good_job.retry_on_unhandled_error = false
  # config.good_job.preserve_job_records = true

  # config.good_job.cron = {
  #   frequent_task: {
  #     cron: "* * * * *",
  #     class: "RecurringThingJob"
  #   }
  # }
end
