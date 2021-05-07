# frozen_string_literal: true

module FastLand
  class Schedule
    class << self
      # Remove old jobs
      def remove_old_jobs()
        Sidekiq::Cron::Job.destroy_all!
      end

      # Add new jobs
      def add_new_jobs(new_jobs:)
        puts "New jobs"
        puts new_jobs
        puts "End new jobs"
        new_jobs.any? && Sidekiq::Cron::Job.load_from_array(new_jobs)
      end

      # Times to jobs
      def update()
        remove_old_jobs()
        new_jobs = []
        cur_schedules = ::Schedule.all
        puts cur_schedules
        puts "new"
        cur_schedules.each_with_index do |cur_schedule, index|
          new_time = cur_schedules[index].start_time
          new_time_array = new_time.split(":")
          time = Time.new(0, 1, 1, new_time_array[0], new_time_array[1], 0)
          timezone_id = cur_schedules[index].timezone_id
          timezone = Timezone.where(id: timezone_id).first[:value]
          operator = timezone[0]
          timezone[0] = ''
          timezone_array = timezone.split(":")
          if(operator == '+')
            time -= Integer(timezone_array[0].to_i) * 3600
            time -= Integer(timezone_array[1].to_i) * 60
          else
            time += Integer(timezone_array[0].to_i) * 3600
            time += Integer(timezone_array[1].to_i) * 60
          end
          frequency = cur_schedules[index].frequency
          for i in 0..frequency - 1 do
            time_string = time.strftime("%H:%M")
            new_jobs << {
              name: FastLand::Utils::Job.job_name(time: time_string),
              class: "FastLand::Worker::Sync",
              cron: FastLand::Utils::Job.cron_time(time: time_string),
            }
            time += (24 / frequency) * 3600
          end
        end
        # Add new jobs
        add_new_jobs(new_jobs: new_jobs)
      end
    end
  end
end
