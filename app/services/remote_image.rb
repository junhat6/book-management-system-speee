require "net/http"

# 許可されたホストの画像URLから、安全にバイト列を取得するクライアント。
# GoogleBooks が「ISBNから書誌メタデータを引く」責務なのに対し、
# こちらは「取得済みの画像URLから安全にバイト列を取る」という別の責務を持つ。
#
# remote_cover_image_url はフォームのhidden fieldから渡ってくる値のため、
# 理論上は改ざんされ得る（SSRF対策）。ホストの完全一致・httpsのみ・
# Content-Typeのallowlist・ストリーミングでのサイズ上限チェックの4段で防御する。
class RemoteImage
  Error = Class.new(StandardError)
  Fetched = Data.define(:io, :filename, :content_type)

  ALLOWED_HOSTS = %w[books.google.com].freeze
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  MAX_BYTES = 5 * 1024 * 1024
  TIMEOUT_SECONDS = 5

  class << self
    def fetch(url)
      uri = validate(url)
      content_type = nil
      body = nil

      # Net::HTTP はリダイレクトを既定で追従しないため、追加のリダイレクト対策は不要
      Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                       open_timeout: TIMEOUT_SECONDS, read_timeout: TIMEOUT_SECONDS) do |http|
        http.request_get(uri.request_uri) do |response|
          raise Error, "画像取得がエラーを返しました（HTTP #{response.code}）" unless response.is_a?(Net::HTTPSuccess)

          content_type = response.content_type
          raise Error, "許可されていないContent-Typeです: #{content_type}" unless ALLOWED_CONTENT_TYPES.include?(content_type)

          body = read_within_limit(response)
        end
      end

      Fetched.new(io: StringIO.new(body), filename: "cover.#{content_type.split('/').last}", content_type: content_type)
    rescue Timeout::Error, SystemCallError, SocketError, IOError, OpenSSL::SSL::SSLError => e
      raise Error, "画像取得中に接続エラーが発生しました: #{e.message}"
    end

    private

    def validate(url)
      uri = URI(url)
      raise Error, "許可されていないURLです: #{url}" unless uri.is_a?(URI::HTTPS) && ALLOWED_HOSTS.include?(uri.host)

      uri
    rescue URI::InvalidURIError => e
      raise Error, "不正なURLです: #{e.message}"
    end

    # Content-Length ヘッダーは省略・詐称され得るため、実際に受信したバイト数で判定する
    def read_within_limit(response)
      buffer = +""
      response.read_body do |chunk|
        buffer << chunk
        raise Error, "画像サイズが上限（#{MAX_BYTES}バイト）を超えています" if buffer.bytesize > MAX_BYTES
      end
      buffer
    end
  end
end
