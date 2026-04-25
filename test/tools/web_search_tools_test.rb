# frozen_string_literal: true

require "test_helper"
require_relative "../../app/tools/tool_base"
require_relative "../../app/tools/web_search_tools"

class WebSearchToolsTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
  end

  test "retorna resultados mapeados em success" do
    stub_request(:get, "http://searxng:8080/search")
      .with(query: hash_including(q: "ruby on rails", format: "json"))
      .to_return(
        status: 200,
        body:   { results: [
          { "title" => "T", "url" => "https://x", "content" => "snippet", "engine" => "duckduckgo" }
        ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = WebSearchTool.new.execute(query: "ruby on rails")
    assert_equal :success, result[:status]
    assert_equal 1, result[:data].size
    assert_equal "https://x", result[:data].first[:url]
  end

  test "trunca content acima de 400 chars" do
    long = "a" * 1000
    stub_request(:get, "http://searxng:8080/search")
      .with(query: hash_including(format: "json"))
      .to_return(
        status: 200,
        body:   { results: [{ "title" => "T", "url" => "u", "content" => long, "engine" => "e" }] }.to_json
      )
    result = WebSearchTool.new.execute(query: "x")
    assert_operator result[:data].first[:content].length, :<=, 401
  end

  test "clampa limit no teto" do
    stub_request(:get, "http://searxng:8080/search")
      .with(query: hash_including(format: "json"))
      .to_return(
        status: 200,
        body:   { results: Array.new(20) { |i| { "title" => i.to_s, "url" => "u#{i}", "content" => "c" } } }.to_json
      )
    result = WebSearchTool.new.execute(query: "x", limit: 999)
    assert_operator result[:data].size, :<=, 10
  end

  test "query vazia retorna error" do
    result = WebSearchTool.new.execute(query: "  ")
    assert_equal :error, result[:status]
    assert_equal "query vazia", result[:reason]
  end

  test "HTTP 500 retorna error sem retry" do
    stub_request(:get, "http://searxng:8080/search")
      .with(query: hash_including(format: "json"))
      .to_return(status: 500)
    result = WebSearchTool.new.execute(query: "x")
    assert_equal :error, result[:status]
  end

  test "resultado é cacheado por query+limit" do
    stub = stub_request(:get, "http://searxng:8080/search")
           .with(query: hash_including(format: "json"))
           .to_return(
             status: 200,
             body:   { results: [{ "title" => "T", "url" => "u", "content" => "c", "engine" => "e" }] }.to_json
           )
    2.times { WebSearchTool.new.execute(query: "cache test") }
    assert_requested stub, times: 1
  end

  test "time_range é anexado como param SearXNG quando válido" do
    stub = stub_request(:get, "http://searxng:8080/search")
           .with(query: hash_including(q: "breaking news", time_range: "day"))
           .to_return(status: 200, body: { results: [] }.to_json)
    WebSearchTool.new.execute(query: "breaking news", time_range: "day")
    assert_requested stub
  end

  test "time_range valores permitidos: day/week/month/year" do
    %w[day week month year].each do |range|
      Rails.cache.clear
      stub = stub_request(:get, "http://searxng:8080/search")
             .with(query: hash_including(time_range: range))
             .to_return(status: 200, body: { results: [] }.to_json)
      WebSearchTool.new.execute(query: "teste #{range}", time_range: range)
      assert_requested stub
    end
  end

  test "time_range inválido é ignorado (não envia param)" do
    stub_request(:get, /searxng:8080\/search/)
      .to_return(status: 200, body: { results: [] }.to_json)
    WebSearchTool.new.execute(query: "x", time_range: "century")
    assert_requested(:get, /searxng:8080\/search/) do |req|
      !req.uri.query.to_s.include?("time_range")
    end
  end

  test "sem time_range, SearXNG é chamado sem o param" do
    stub_request(:get, /searxng:8080\/search/)
      .to_return(status: 200, body: { results: [] }.to_json)
    WebSearchTool.new.execute(query: "sem filtro de data")
    assert_requested(:get, /searxng:8080\/search/) do |req|
      !req.uri.query.to_s.include?("time_range")
    end
  end

  test "cache é keyed separadamente por time_range" do
    stub_request(:get, /searxng:8080\/search/)
      .with(query: hash_including(time_range: "day"))
      .to_return(status: 200, body: { results: [{ "title" => "t1", "url" => "u1", "content" => "c" }] }.to_json)
    stub_request(:get, /searxng:8080\/search/)
      .with(query: hash_including(format: "json"))
      .to_return(status: 200, body: { results: [{ "title" => "t2", "url" => "u2", "content" => "c" }] }.to_json)
    WebSearchTool.new.execute(query: "placar", time_range: "day")
    WebSearchTool.new.execute(query: "placar")
    assert_requested(:get, /searxng:8080\/search/, times: 2)
  end
end
