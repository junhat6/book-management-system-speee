admin_user = User.find_or_initialize_by(email_address: "admin@example.com")
admin_user.assign_attributes(
  name: "管理者",
  password: "12345678",
  password_confirmation: "12345678",
  admin: true
)
admin_user.save!

general_user = User.find_or_initialize_by(email_address: "user@example.com")
general_user.assign_attributes(
  name: "一般ユーザー",
  password: "12345678",
  password_confirmation: "12345678",
  admin: false
)
general_user.save!

fitzgerald = Author.find_or_create_by!(name: "F. Scott Fitzgerald")
lee = Author.find_or_create_by!(name: "Harper Lee")

gatsby = Book.find_or_initialize_by(isbn: "978-3-16-148410-0")
gatsby.assign_attributes(
  title: "The Great Gatsby",
  published_year: 1925,
  publisher: "Scribner",
  new_author_name: fitzgerald.name
)
gatsby.save!

mockingbird = Book.find_or_initialize_by(isbn: "978-0-06-112008-4")
mockingbird.assign_attributes(
  title: "To Kill a Mockingbird",
  published_year: 1960,
  publisher: "J.B. Lippincott & Co.",
  new_author_name: lee.name
)
mockingbird.save!
