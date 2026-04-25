# frozen_string_literal: true

require "test_helper"
require_relative "../../app/tools/tool_base"
require_relative "../../app/tools/page_fetch_tools"

class PageFetchToolTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    ENV["ENABLE_PAGE_FETCH"] = "true"
  end

  teardown do
    ENV["ENABLE_PAGE_FETCH"] = nil
  end

  def stub_fetch(payload = nil)
    payload ||= {
      title: "Ferramentas Cleitin",
      url: "https://example.com/doc",
      content: "Conteúdo extraído da página",
      truncated: false,
      char_count: 30,
      fetched_at: Time.current,
      cache_age_seconds: 0
    }
    Fetcher::PageFetcher.stubs(:call).returns(payload)
    payload
  end

  test "retorna success quando fetch bem-sucedido" do
    stub_fetch
    result = PageFetchTool.new.execute(url: "https://example.com/doc")
    assert_equal :success, result[:status]
    assert_includes result[:data][:content], "extraído"
    assert_equal "https://example.com/doc", result[:data][:url]
  end

  test "url vazia retorna error" do
    result = PageFetchTool.new.execute(url: "  ")
    assert_equal :error, result[:status]
    assert_match(/vazia/i, result[:reason])
  end

  test "feature flag desligada retorna error" do
    ENV["ENABLE_PAGE_FETCH"] = "false"
    result = PageFetchTool.new.execute(url: "https://example.com/")
    assert_equal :error, result[:status]
    assert_match(/desabilit/i, result[:reason])
  end

  test "ENABLE_PAGE_FETCH ausente é tratado como desligada" do
    ENV.delete("ENABLE_PAGE_FETCH")
    result = PageFetchTool.new.execute(url: "https://example.com/")
    assert_equal :error, result[:status]
  end

  test "limit_chars é clampado (500..8000)" do
    stub_fetch
    Fetcher::PageFetcher.expects(:call).with("https://example.com/").returns(
      { title: "t", url: "https://example.com/", content: "x", truncated: false, char_count: 1,
        fetched_at: Time.current, cache_age_seconds: 0 }
    )
    result = PageFetchTool.new.execute(url: "https://example.com/", limit_chars: 9999)
    assert_equal :success, result[:status]
  end

  test "SsrfGuard::Blocked é convertido em error" do
    Fetcher::PageFetcher.stubs(:call).raises(Fetcher::SsrfGuard::Blocked.new("host privado (10.0.0.1)"))
    result = PageFetchTool.new.execute(url: "http://10.0.0.1/")
    assert_equal :error, result[:status]
    assert_match(/privado/i, result[:reason])
  end

  test "RateLimited é convertido em error" do
    Fetcher::PageFetcher.stubs(:call).raises(Fetcher::PageFetcher::RateLimited.new("example.com"))
    result = PageFetchTool.new.execute(url: "https://example.com/")
    assert_equal :error, result[:status]
    assert_match(/rate limit/i, result[:reason])
  end

  test "HostInCooldown é convertido em error com remaining time" do
    entry = { blocked_at: Time.current - 1.hour, expires_at: Time.current + 5.hours, reason: "403" }
    Fetcher::PageFetcher.stubs(:call).raises(Fetcher::PageFetcher::HostInCooldown.new("example.com", entry))
    result = PageFetchTool.new.execute(url: "https://example.com/")
    assert_equal :error, result[:status]
    assert_match(/cooldown/i, result[:reason])
  end

  test "BotBlocked é convertido em error" do
    Fetcher::PageFetcher.stubs(:call).raises(Fetcher::PageFetcher::BotBlocked.new("example.com", "Just a moment..."))
    result = PageFetchTool.new.execute(url: "https://example.com/")
    assert_equal :error, result[:status]
  end

  test "PdfNotSupported é convertido em error claro" do
    Fetcher::PageFetcher.stubs(:call).raises(Fetcher::PageFetcher::PdfNotSupported.new)
    result = PageFetchTool.new.execute(url: "https://example.com/paper.pdf")
    assert_equal :error, result[:status]
    assert_match(/PDF/i, result[:reason])
  end

  test "RenderTimeout é convertido em error" do
    Fetcher::PageFetcher.stubs(:call).raises(Fetcher::PageFetcher::RenderTimeout.new)
    result = PageFetchTool.new.execute(url: "https://example.com/")
    assert_equal :error, result[:status]
    assert_match(/timeout/i, result[:reason])
  end

  test "exceção genérica não vaza stacktrace — retorna error genérico" do
    Fetcher::PageFetcher.stubs(:call).raises(StandardError.new("boom"))
    result = PageFetchTool.new.execute(url: "https://example.com/")
    assert_equal :error, result[:status]
    assert_match(/falha|erro/i, result[:reason])
  end

  test "data inclui todos os campos: title, url, content, truncated, char_count, fetched_at, cache_age_seconds" do
    stub_fetch
    result = PageFetchTool.new.execute(url: "https://example.com/")
    %i[title url content truncated char_count fetched_at cache_age_seconds].each do |key|
      assert result[:data].key?(key), "esperava #{key} no data"
    end
  end

  test "limit_chars respeita o teto silent-clamp" do
    stub_fetch(
      { title: "t", url: "https://example.com/", content: "x" * 10_000,
        truncated: false, char_count: 10_000,
        fetched_at: Time.current, cache_age_seconds: 0 }
    )
    result = PageFetchTool.new.execute(url: "https://example.com/", limit_chars: 6000)
    assert_equal :success, result[:status]
    assert_operator result[:data][:content].length, :<=, 6000
    assert_equal true, result[:data][:truncated]
  end
end
