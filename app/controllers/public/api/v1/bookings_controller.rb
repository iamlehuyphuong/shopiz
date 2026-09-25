class Public::Api::V1::BookingsController < PublicController
  before_action :fetch_configuration

  # GET /public/api/v1/bookings/:hash
  def show
    render json: {
      account_name: @configuration.account.name,
      meeting_duration: @configuration.meeting_duration,
      working_hours: @configuration.booking_working_hours
    }
  end

  # POST /public/api/v1/bookings/:hash
  def create
    start_time = Time.zone.parse(params[:start_time])
    end_time = start_time + @configuration.meeting_duration.minutes

    manager = CalendarService::EventManager.new(@configuration.account)
    event_id = manager.create_event(
      start_time: start_time,
      end_time: end_time,
      guest_email: params[:guest_email],
      guest_name: params[:guest_name],
      description: params[:notes]
    )

    if event_id
      booking = @configuration.account.bookings.create!(
        start_time: start_time,
        end_time: end_time,
        guest_name: params[:guest_name],
        guest_email: params[:guest_email],
        google_event_id: event_id,
        provider: 'google',
        status: :scheduled
      )
      render json: booking
    else
      render json: { error: 'Failed to create booking on Google Calendar' }, status: :unprocessable_entity
    end
  end

  private

  def fetch_configuration
    @configuration = BookingConfiguration.find_by!(booking_link_hash: params[:hash], is_active: true)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid or inactive booking link' }, status: :not_found
  end
end
