class ApplicationMailer < ActionMailer::Base
  # onboarding@resend.dev is Resend's shared sandbox sender — it works without
  # verifying a custom domain, but can only deliver to the email address that
  # owns the Resend account. Swap in a verified domain address if that changes.
  default from: "onboarding@resend.dev"
  layout "mailer"
end
