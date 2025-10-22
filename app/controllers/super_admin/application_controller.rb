# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
class SuperAdmin::ApplicationController < Administrate::ApplicationController
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include SuperAdmin::NavigationHelper

  helper_method :render_vue_component, :settings_open?, :settings_pages, :load_plans
  # authenticiation done via devise : SuperAdmin Model
  before_action :authenticate_super_admin!

  # Override this value to specify the number of elements to display at a time
  # on index pages. Defaults to 20.
  # def records_per_page
  #   params[:per_page] || 20
  # end

  def order
    @order ||= Administrate::Order.new(
      params.fetch(resource_name, {}).fetch(:order, 'id'),
      params.fetch(resource_name, {}).fetch(:direction, 'desc')
    )
  end

  private

  def render_vue_component(component_name, props = {})
    html_options = {
      id: 'app',
      data: {
        component_name: component_name,
        props: props.to_json
      }
    }
    content_tag(:div, '', html_options)
  end

  def load_plans
    Polar.configure do |config|
      config.access_token = ENV.fetch('POLAR_ACCESS_TOKEN')
      config.sandbox = ENV.fetch('POLAR_ENV') == 'sandbox'
    end

    products = Polar::Product.list({ limit: 50 })
    products.map(&:table).map do |product|
      name = if %w[Trial Enterprise].include?(product[:name])
               product[:name]
             else
               "#{product[:name]} #{Enterprise::Billing::PlanMapper.get_duration(product[:id])}"
             end

      [name, product[:id]]
    end
  rescue StandardError
    []
  end

  def invalid_action_perfomed
    # rubocop:disable Rails/I18nLocaleTexts
    flash[:error] = 'Invalid action performed'
    # rubocop:enable Rails/I18nLocaleTexts
    redirect_back(fallback_location: root_path)
  end
end
