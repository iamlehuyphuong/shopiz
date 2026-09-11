class Payments::ProviderRegistry
  @providers = {}

  class << self
    def register(name, provider_class)
      @providers[name.to_s] = provider_class
    end

    def provider_for(name)
      @providers[name.to_s]
    end

    def registered_providers
      @providers.keys
    end
  end
end
