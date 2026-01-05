system_email = ENV["INITIAL_SYSTEM_EMAIL"]
system_user = ENV["INITIAL_SYSTEM_USERNAME"]
system_pass = ENV["INITIAL_SYSTEM_PASSWORD"]

if system_email.present? && system_user.present? && system_pass.present?
    user = User.find_or_initialize_by(email: system_email)
    if user.new_record?
        user.email = system_email
        user.username = system_user
        user.password = system_pass
        user.password_confirmation = system_pass
        user.role = :admin
        user.save!
        puts "Created initial admin user: #{system_user} (#{system_email})"
    else
        puts "Admin user already exists: #{system_user} (#{system_email})"
    end
else
    puts "Skipping production seeding. INITIAL_SYSTEM_EMAIL, INITIAL_SYSTEM_USERNAME, or INITIAL_SYSTEM_PASSWORD environment variables are not set."
end
