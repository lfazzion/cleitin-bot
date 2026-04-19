# frozen_string_literal: true

module Llm
  class GemmaClient < BaseClient
    # Gemma 4 31B (instruction-tuned): Ilimitado TPM, 1.500 RPD
    MODEL_ID = 'gemma-4-31b-it'
    MAX_DAILY = 1_450 # margem de segurança dos 1.500 RPD
    TPM_SAFE_THRESHOLD = Float::INFINITY # sem limite de TPM, não escala mais para OpenRouter baseado em size

    def model_id = MODEL_ID
    def daily_quota_key = 'gemma_daily'
    def max_daily_requests = MAX_DAILY

    def self.tpm_safe_threshold
      TPM_SAFE_THRESHOLD
    end
  end
end
