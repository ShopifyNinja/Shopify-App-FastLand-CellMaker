require 'date'

class Api::V1::SettingsController < AuthenticatedController
  # Load settings
  def index
    schedule = Schedule.last
    logs = SyncLog.limit(10)
    new_logs = []
    timezone_id = 0
    timezone = ''
    timezone_array = []
    operator = ''
    
    if Schedule.last
      timezone_id = Schedule.last[:timezone_id]
      timezone = Timezone.where(id: timezone_id).first[:value]
    else
      timezone = "+00:00"
    end
    operator = timezone[0]
    timezone[0] = ''
    timezone_array = timezone.split(":") 
    
    logs.each_with_index do |log, index|
      log_start_time = log[:start_at]
      if log[:end_at] == nil
        log_end_time = nil
      else
        log_end_time = log[:end_at]
      end
      
      if(operator == '+')
        log_start_time += Integer(timezone_array[0].to_i) * 3600
        log_start_time += Integer(timezone_array[1].to_i) * 60
        unless log_end_time == nil
          log_end_time += Integer(timezone_array[0].to_i) * 3600
          log_end_time += Integer(timezone_array[1].to_i) * 60
        end
      else
        log_start_time -= Integer(timezone_array[0].to_i) * 3600
        log_start_time -= Integer(timezone_array[1].to_i) * 60
        unless log_end_time == nil
          log_end_time -= Integer(timezone_array[0].to_i) * 3600
          log_end_time -= Integer(timezone_array[1].to_i) * 60
        end
      end

      log[:start_at] = log_start_time.strftime("%Y-%m-%d %H:%M:%S")
      log[:end_at] = log_end_time.strftime("%Y-%m-%d %H:%M:%S")
      new_logs.push(log)
    end
    timezones = Timezone.all
    if schedule.present?
      render json: {
        start_time: schedule.start_time,
        frequency: schedule.frequency.to_s,
        timezone: Timezone.where(id: schedule.timezone_id).first.value,
        logs: logs,
        timezones: timezones
      }
    else
      render json: {
        start_time: "00:00",
        frequency: "1",
        timezone: 1,
        logs: new_logs,
        timezones: timezones
      }
    end
  end

  # Save settings
  def save
    # Update schedules
    scheudle = Schedule.last || Schedule.new
    scheudle.start_time = times_params[:start_time]
    scheudle.frequency = times_params[:frequency]
    scheudle.timezone_id = Timezone.where(value: times_params[:timezone]).first.id
    scheudle.save

    # Update Sikekiq jobs
    FastLand::Schedule.update()

    render json: {}
  end

  # Get Cell Maker settings
  def cell_maker
    setting = Setting.last

    render json: { base_url: setting&.base_url, master_wizard_id: setting&.master_wizard_id }
  end

  # Update Cell Maker settings
  def update_cell_maker
    setting = Setting.last || Setting.new
    setting.base_url = cell_maker_params[:base_url]
    setting.master_wizard_id = cell_maker_params[:master_wizard_id]
    setting.save

    render json: { status: true }
  end

  private
    def times_params
      params.permit(:start_time, :frequency, :timezone)
    end

    def cell_maker_params
      params.require(:setting).permit(:base_url, :master_wizard_id)
    end
end
