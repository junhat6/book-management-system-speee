class BooksController < ApplicationController
  def index
    @books = Book.order(created_at: :desc)
  end

  def show
    @book = Book.find(params[:id])
  end

  def new
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)
    if @book.save
      redirect_to @book, notice: "Book was successfully created."
    else
      render :new
    end
  end

  private

  def book_params
    params.require(:book).permit(:title, :isbn, :published_year, :publisher)
  end
end
