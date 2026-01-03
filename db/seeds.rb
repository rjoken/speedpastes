# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
User.find_or_create_by!(email: "admin@speedpastes.org") do |user|
    user.username = "admin"
    user.password = "hunter2"
    user.password_confirmation = "hunter2"
    user.bio = "Seeded admin user. Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    user.link = "https://speedpastes.org"
end

InviteCode.find_or_create_by!(code: "INVITE") do |invite|
    invite.max_uses = 100
    invite.uses_count = 0
    invite.created_by = User.find_by(username: "admin")
end
