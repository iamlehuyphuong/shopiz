class Api::V1::Accounts::BookingConfigurationsController < Api::V1::Accounts::BaseController
  before_action :fetch_configuration, only: [:show, :update]

  def show
    if @configuration
      render json: @configuration, include: :booking_working_hours
    else
      render json: {}, status: :not_found
    end
  end

  def update
    @configuration ||= Current.account.build_booking_configuration
    @configuration.assign_attributes(configuration_params)

    # Generate booking link hash if empty
    @configuration.booking_link_hash = SecureRandom.hex(10) if @configuration.booking_link_hash.blank?

    if @configuration.save
      update_working_hours(params[:working_hours]) if params[:working_hours]
      render json: @configuration, include: :booking_working_hours
    else
      render json: { error: @configuration.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def fetch_configuration
    @configuration = Current.account.booking_configuration
  end

  def configuration_params
    params.require(:booking_configuration).permit(
      :meeting_duration,
      :buffer_time,
      :is_active
    )
  end

  def update_working_hours(hours_params)
    hours_params.each do |hour_param|
      wh = @configuration.booking_working_hours.find_or_initialize_by(day_of_week: hour_param[:day_of_week])
      wh.update!(
        open_hour: hour_param[:open_hour],
        open_minutes: hour_param[:open_minutes],
        close_hour: hour_param[:close_hour],
        close_minutes: hour_param[:close_minutes],
        closed_all_day: hour_param[:closed_all_day],
        open_all_day: hour_param[:open_all_day]
      )
    end
  end
end
