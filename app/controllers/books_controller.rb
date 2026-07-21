class BooksController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]
  before_action :require_admin, except: [ :index, :show ]
  before_action :set_book, only: [ :show, :edit, :update, :destroy ]
  before_action :prepare_authors, only: [ :new, :edit, :create, :update ]
  before_action :prepare_tags, only: [ :index, :new, :edit, :create, :update ]

  def index
    # 存在しない tag_id は絞り込みなしとして扱う（フィルタ表示も出さない）
    @current_tag = Tag.find_by(id: params[:tag_id])
    @books = Book.search(params[:q]).with_tag(@current_tag&.id)
                 .includes(:authors, :tags, copies: :rentals)
                 .with_attached_cover_image
                 .sorted(params[:sort], params[:direction])
                 .page(params[:page])
  end

  def show
  end

  def new
    @book = Book.new
    prefill_from_google_books if params[:lookup_isbn].present?
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
    @book = Book.includes(:authors, :tags, copies: :rentals).find(params[:id])
  end

  def prepare_authors
    @authors = Author.order(:name)
  end

  def prepare_tags
    @tags = Tag.order(:name)
  end

  def book_params
    params.require(:book).permit(:title, :isbn, :published_year, :publisher, :new_author_names, :new_tag_names, :initial_stock_count, :remote_cover_image_url, author_ids: [], tag_ids: [])
  end

  # 発展要件6: ISBN から Google Books API で書誌情報を取得し、フォーム初期値に反映する。
  # コントローラは結果の「状態」（@lookup_result）だけを決め、表示文言は view に置く。
  # 取得失敗は登録を妨げない（メッセージを出して手入力にフォールバック）
  def prefill_from_google_books
    @book.isbn = GoogleBooks.normalize(params[:lookup_isbn])
    volume = GoogleBooks.lookup(params[:lookup_isbn])

    if volume
      @book.title = volume.title
      @book.publisher = volume.publisher
      @book.published_year = volume.published_year
      @book.new_author_names = volume.authors.join("、")
      @book.remote_cover_image_url = volume.image_url
      @lookup_result = :found
    else
      @lookup_result = :not_found
    end
  rescue GoogleBooks::Error => e
    Rails.logger.warn("Google Books lookup failed: #{e.message}")
    @lookup_result = :error
  end
end
