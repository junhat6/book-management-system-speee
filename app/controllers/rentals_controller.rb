class RentalsController < ApplicationController
  rescue_from ActiveRecord::RecordNotUnique, with: :copy_just_rented

  before_action :set_book, only: :create
  before_action :set_own_active_rental, only: :update

  def index
    @rentals = rental_scope.includes(:user, :book)
                           .with_status(params[:status])
                           .sorted(params[:sort], params[:direction])
                           .page(params[:page])
  end

  def create
    copy = @book.available_copy
    if copy.nil?
      return redirect_to @book, alert: "在庫がないため借りられません。"
    end

    @rental = Rental.new(user: Current.user, book_copy: copy)
    if @rental.save
      redirect_to @book, notice: "「#{@book.title}」を借りました。"
    else
      redirect_to @book, alert: @rental.errors.full_messages.to_sentence
    end
  end

  def update
    @rental.update!(returned_at: Time.current)
    redirect_to @rental.book, notice: "「#{@rental.book.title}」を返却しました。"
  end

  private

  def rental_scope
    admin? ? Rental.all : Current.user.rentals
  end

  def set_book
    @book = Book.find(params[:book_id])
  end

  def set_own_active_rental
    @rental = Current.user.rentals.active.find(params[:id])
  end

  def copy_just_rented
    redirect_to @book, alert: "ちょうど最後の在庫が貸し出されたため借りられませんでした。"
  end
end
