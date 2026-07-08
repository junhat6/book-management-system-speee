require "net/http"

# ISBN をキーに Google Books API から書誌情報を取得するクライアント。
# https://developers.google.com/books/docs/v1/using
#
# 戻り値の使い分け：
#   - ヒット       → Volume（title / authors / publisher / published_year）
#   - ヒットなし   → nil（正常系。呼び出し側は手入力を促す）
#   - 通信・API異常 → GoogleBooks::Error（異常系。呼び出し側で rescue する）
class GoogleBooks
  Error = Class.new(StandardError)
  Volume = Data.define(:title, :authors, :publisher, :published_year)

  API_URL = "https://www.googleapis.com/books/v1/volumes".freeze
  TIMEOUT_SECONDS = 5

  class << self
    def lookup(isbn)
      normalized = normalize(isbn)
      return nil if normalized.empty?

      parse(request(normalized))
    end

    # ハイフン・空白の揺れを吸収する（"978-4-..." と "9784..." を同一視するため）
    def normalize(isbn)
      isbn.to_s.gsub(/[\s-]/, "")
    end

    private

    def request(isbn)
      uri = URI(API_URL)
      query = { q: "isbn:#{isbn}" }
      # API キー無しの匿名リクエストは全世界で共有される極小クォータしか無く、すぐ 429 になる。
      # キーがあればプロジェクト固有のクォータで問い合わせられるため、設定されている場合のみ付与する。
      query[:key] = ENV["GOOGLE_BOOKS_API_KEY"] if ENV["GOOGLE_BOOKS_API_KEY"].present?
      uri.query = URI.encode_www_form(query)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                 open_timeout: TIMEOUT_SECONDS, read_timeout: TIMEOUT_SECONDS) do |http|
        http.get(uri.request_uri)
      end
      raise Error, "Google Books API がエラーを返しました（HTTP #{response.code}）" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue Timeout::Error, SystemCallError, SocketError, IOError, OpenSSL::SSL::SSLError => e
      raise Error, "Google Books API に接続できませんでした: #{e.message}"
    rescue JSON::ParserError => e
      raise Error, "Google Books API の応答を解析できませんでした: #{e.message}"
    end

    def parse(json)
      info = json.dig("items", 0, "volumeInfo")
      return nil if info.nil? || info["title"].blank?

      Volume.new(
        title: info["title"],
        authors: Array(info["authors"]),
        publisher: info["publisher"],
        # "2012-06" や "1914" のような形式差があるため、先頭の4桁だけを年として使う
        published_year: info["publishedDate"]&.slice(/\d{4}/)&.to_i
      )
    end
  end
end
