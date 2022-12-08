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

  # ZoomのAPIから、ミーティングに参加しているユーザーの一覧を取得し、そのユニーク値をかえす
  #
  # APIの仕様上、leaveしたユーザーも結果として返ってくるため、一度leaveして再度joinしたユーザーが重複する。
  # そのため、IDでユニークを保証する。
  #
  # IDに関して、zoomにログインせずに参加しているユーザーはIDの項目が用意されない。
  # そのため、IDがないユーザーに関してはユーザー名でユニークを取る。
  #
  # また、一度leaveしたユーザーはleave_reasonがセットされるので、leave_reasonがあるユーザーは事前に除外する。
  #
  # See also https://marketplace.zoom.us/docs/api-reference/zoom-api/dashboards/dashboardmeetingparticipants
  #
  def users_list(meeting_id)
    users = @client.dashboard_meeting_participants(meeting_id: meeting_id)["participants"]
    pp users
    current_users = users.reject { |user| user["leave_reason"] }
    pp current_users
    users_with_id, users_without_id = current_users.partition { |user| user["id"] }

    uniq_users_with_id = users_with_id.uniq { |user| user["id"] }
    uniq_users_without_id = users_without_id.uniq { |user| user["user_name"] }

    (uniq_users_with_id + uniq_users_without_id).map { |user| user["user_name"] }
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

    query = "https://headless-gacha.kinoppyd.dev/?items=#{ascii_items.join(",")}"
    conn.get(query)
  end

  class Helper
    def self.only_ascii(string)
      string.gsub(/[^a-zA-Z ,]/, "")
    end
  end
end
