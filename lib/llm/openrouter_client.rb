# frozen_string_literal: true

module Llm
  class OpenrouterClient < BaseClient
    # Gemma 4 31B via OpenRouter — fallback gratuito
    MODEL_ID = 'google/gemma-4-31b-it:free'
    MAX_DAILY = 400 # conservador para tier gratuito/pago básico

    def model_id = MODEL_ID
    def daily_quota_key = 'openrouter_daily'
    def max_daily_requests = MAX_DAILY
  end
end
