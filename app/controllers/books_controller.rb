class BooksController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]
  before_action :require_admin, except: [ :index, :show ]
  before_action :set_book, only: [ :show, :edit, :update, :destroy ]
  before_action :prepare_authors, only: [ :new, :edit, :create, :update ]

  def index
    @books = Book.search(params[:q]).includes(:authors, copies: :rentals).order(created_at: :desc)
  end

  def show
  end

  def new
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)
    if @book.save
      redirect_to @book, notice: "Book was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @book.update(book_params)
      redirect_to @book, notice: "Book was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @book.destroy
      redirect_to books_path, notice: "Book was successfully destroyed.", status: :see_other
    else
      redirect_to @book, alert: @book.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_book
    @book = Book.includes(:authors, copies: :rentals).find(params[:id])
  end

  def prepare_authors
    @authors = Author.order(:name)
  end

  def book_params
    params.require(:book).permit(:title, :isbn, :published_year, :publisher, :new_author_name, :initial_stock_count, author_ids: [])
  end
end
