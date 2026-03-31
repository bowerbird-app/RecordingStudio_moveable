# frozen_string_literal: true

GemTemplate.configure do |config|
  # Set your API key (recommended to use ENV or Rails credentials)
  # config.api_key = ENV["GEM_TEMPLATE_API_KEY"]

  # Enable optional feature X
  # config.enable_feature_x = false

  # Timeout in seconds for external calls
  # config.timeout = 5

  # Prefetch move modal responses when users hover or focus a modal trigger link.
  # config.move_modal_prefetch_enabled = true

  # Delay before hover/focus prefetch begins.
  # config.move_modal_prefetch_delay_ms = 80

  # How long prefetched move modal responses stay warm in the client cache.
  # config.move_modal_prefetch_ttl_ms = 10_000

  # Reuse a single gem-owned modal shell between openings.
  # config.move_modal_reuse_shell = true
end
