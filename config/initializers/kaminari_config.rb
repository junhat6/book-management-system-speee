# frozen_string_literal: true

Kaminari.configure do |config|
  config.default_per_page = 10
  # 先頭・末尾ページへのリンクを常に1つ出す（「1 2 3 4 5 … 16」の形にする）
  config.outer_window = 1
end
