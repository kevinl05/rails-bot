require "net/http"
require "json"

module RailsBot
  class DhhFeed
    BLUESKY_URL = "https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor=dhh.bsky.social&limit=10"
    HEY_WORLD_URL = "https://world.hey.com/dhh/feed.atom"
    CACHE_TTL = 1.hour

    def self.fetch
      new.fetch
    end

    def fetch
      Rails.cache.fetch("dhh_feed", expires_in: CACHE_TTL) do
        posts = []
        posts.concat(fetch_bluesky)
        posts.concat(fetch_hey_world)
        posts.first(15)
      end
    rescue => e
      Rails.logger.warn("Failed to fetch DHH feed: #{e.message}")
      []
    end

    private

    def fetch_bluesky
      uri = URI(BLUESKY_URL)
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)

      data["feed"]&.map do |item|
        post = item["post"]
        text = post.dig("record", "text")
        next if text.blank?

        "[Bluesky] #{text}"
      end.compact
    rescue => e
      Rails.logger.warn("Bluesky fetch failed: #{e.message}")
      []
    end

    def fetch_hey_world
      uri = URI(HEY_WORLD_URL)
      xml = Net::HTTP.get(uri)
      doc = Nokogiri::XML(xml)
      doc.remove_namespaces!

      doc.css("entry").first(5).map do |entry|
        title = entry.at_css("title")&.text
        next if title.blank?

        "[Blog] #{title}"
      end.compact
    rescue => e
      Rails.logger.warn("HEY World fetch failed: #{e.message}")
      []
    end
  end
end
