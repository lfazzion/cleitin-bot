# frozen_string_literal: true

# config/initializers/ruby_llm.rb
#
# Configuração global do RubyLLM. Suporta Gemini nativamente e OpenRouter
# via openrouter_api_key. O provider é escolhido automaticamente pelo
# prefixo do model_id (ex: 'google/gemini-*' → Gemini, 'anthropic/*' → OpenRouter).

begin
  require 'ruby_llm'

  # Registra custom model no RubyLLM para evitar ModelNotFoundError com a API do Gemini
  RubyLLM::Models.all << RubyLLM::Model::Info.new(
    id: 'gemma-4-31b-it',
    name: 'Gemma 4 31B',
    provider: 'gemini',
    max_output_tokens: 32768,
    context_window: 262144
  )

  # Registra modelo novo da OpenRouter explicitamente
  RubyLLM::Models.all << RubyLLM::Model::Info.new(
    id: 'openai/gpt-oss-120b:free',
    name: 'GPT OSS 120B Free',
    provider: 'openrouter',
    max_output_tokens: 131072,
    context_window: 131072
  )

  RubyLLM.configure do |config|
    config.gemini_api_key = ENV.fetch('GOOGLE_AI_API_KEY', nil)
    config.openrouter_api_key = ENV.fetch('OPENROUTER_API_KEY', nil)
    config.default_model = 'openai/gpt-oss-120b:free'
    config.logger = Rails.logger
    config.log_level = Rails.env.production? ? :info : :debug
    config.request_timeout = 120
  end
rescue LoadError => e
  Rails.logger.warn "[RubyLLM] Gem não disponível: #{e.message}. Funcionalidade LLM desabilitada."
end
