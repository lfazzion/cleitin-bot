source 'https://rubygems.org'

ruby '~> 4.0'

gem 'rails', '~> 8.1.0'
gem 'sqlite3', '~> 2.6'
gem 'puma', '~> 6.0'
gem 'solid_queue', '~> 1.0'
gem 'solid_cache', '~> 1.0'
gem 'redis', '>= 4.0.1'

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
end

group :test do
  gem 'minitest', '~> 5.0'
  gem 'minitest-reporters'
  gem 'webmock'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'mocha'
end

gem 'ferrum', '~> 0.17.2'  # Headless Chrome via WebSocket (chromedp/headless-shell) — 0.17.2: dockerize + reset fix
gem 'typhoeus', '~> 1.4' # HTTP client com proxy e SSL support
gem 'ssrf_filter', '~> 1.5'  # SSRF + DNS rebinding protection (PageFetchTool)
gem 'ruby-readability', '~> 0.7.3', require: 'readability'  # Fallback extractor (PageFetchTool)
gem 'bootsnap', require: false
gem 'ruby_llm', '~> 1.14'  # Unificada: Gemini + OpenRouter + Tool Calling + Imagen
gem 'discordrb', '~> 3.7'
gem 'tzinfo-data'
