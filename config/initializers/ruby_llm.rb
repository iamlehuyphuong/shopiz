RubyLLM.configure do |config|
  config.use_new_acts_as = true
end

module RubyLLM
  class << self
    alias original_config config

    def config
      Thread.current[:ruby_llm_config] || original_config
    end
  end
end
