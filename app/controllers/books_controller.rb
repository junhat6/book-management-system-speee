class BooksController < ApplicationController
  def index
    @books = Book.order(created_at: :desc)
  end
end
