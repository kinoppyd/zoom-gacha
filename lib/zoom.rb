class ZoomClient
  require 'zoom_rb'

  Zoom.configure do |c|
    c.api_key = ENV['ZOOM_API_KEY']
    c.api_secret = ENV['ZOOM_API_SECRET']
  end

  def initialize
    @client = Zoom.new
  end

  def meeting_name(meeting_id)
    @client.meeting_get(meeting_id: meeting_id)["topic"]
  end

  def users_list(meeting_id)
    @client.dashboard_meeting_participants(meeting_id: meeting_id)["participants"].map { |h| h["user_name"] }
  end
end

class HeadlessGachaClient
  require 'faraday'
  require 'faraday_middleware'

  def gacha(items)
    conn = Faraday.new do |f|
      f.use Faraday::Request::UrlEncoded
      f.use FaradayMiddleware::FollowRedirects
    end

    ascii_items = items.map { |item| Helper.only_ascii(item) }

    query = "https://headless-gacha.herokuapp.com/?items=#{ascii_items.join(",")}"
    conn.get(query)
  end

  class Helper
    def self.only_ascii(string)
      string.gsub(/[^a-zA-Z ,]/, "")
    end
  end
end
