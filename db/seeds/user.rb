begin
  User.create! email_address: "you@example.org", password: "s3cr3t", password_confirmation: "s3cr3t"
rescue ActiveRecord::RecordInvalid => e
  puts "Error creating user #{e.message}"
rescue => e
  puts "Unexpected error #{e.message}"
end
