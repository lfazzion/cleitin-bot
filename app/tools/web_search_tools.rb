# frozen_string_literal: true

require "net/http"
require "json"
require "digest"

class WebSearchTool < ToolBase
  description "Pesquisa web em tempo real via SearXNG. Use para fatos atuais, notícias, " \
              "preços, eventos, documentação externa — APENAS quando as tools internas não cobrirem. " \
              "Passe time_range='day'|'week'|'month'|'year' para perguntas sobre 'último', 'agora', " \
              "'hoje', 'esta semana' (filtra por recência; senão buscador prioriza relevância e pode " \
              "devolver artigo antigo com bom SEO)."

  param :query, type: :string,  desc: "Consulta de busca (5-200 chars)", required: true
  param :limit, type: :integer, desc: "Número máximo de resultados (1-10, padrão 5)", required: false
  param :time_range, type: :string, desc: "Filtro de recência: day|week|month|year. Use para último/agora/hoje/esta-semana.", required: false

  BASE_URL          = ENV.fetch("SEARXNG_URL", "http://searxng:8080/search")
  CONTENT_MAX_CHARS = 400
  CACHE_TTL         = 15.minutes
  ALLOWED_TIME_RANGES = %w[day week month year].freeze

  def run(query:, limit: 5, time_range: nil)
    q = query.to_s.strip
    return error("query vazia") if q.empty?
    return error("query muito longa") if q.length > 200

    limit = clamp(limit, 1, 10)
    tr = ALLOWED_TIME_RANGES.include?(time_range.to_s) ? time_range.to_s : nil
    cache_key = "web_search:#{Digest::SHA256.hexdigest("#{q}|#{limit}|#{tr}")}"
    cached = Rails.cache.read(cache_key)
    return success(cached) if cached

    results = fetch(q, limit, tr)
    return error("busca indisponível") if results.nil?

    Rails.cache.write(cache_key, results, expires_in: CACHE_TTL)
    success(results)
  end

  private

  def fetch(query, limit, time_range)
    uri = URI(BASE_URL)
    params = { q: query, format: "json", safesearch: 1, language: "pt-BR" }
    params[:time_range] = time_range if time_range
    uri.query = URI.encode_www_form(params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 20

    req = Net::HTTP::Get.new(uri)
    req["Accept"] = "application/json"

    response = http.request(req)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn "[WebSearchTool] HTTP #{response.code}"
      return nil
    end

    JSON.parse(response.body).fetch("results", []).first(limit).map do |r|
      {
        title:   r["title"],
        url:     r["url"],
        content: truncate(r["content"]),
        engine:  r["engine"]
      }
    end
  rescue StandardError => e
    Rails.logger.error "[WebSearchTool] #{e.class}: #{e.message}"
    nil
  end

  def truncate(text)
    return nil if text.nil?

    text.length > CONTENT_MAX_CHARS ? "#{text[0, CONTENT_MAX_CHARS]}…" : text
  end
end
