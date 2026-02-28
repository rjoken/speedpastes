puts "Seeding development..."

User.find_or_create_by!(email: "admin@speedpastes.org") do |user|
    user.username = "admin"
    user.password = "hunter2"
    user.password_confirmation = "hunter2"
    user.bio = "Seeded admin user. Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    user.link = "https://speedpastes.org"
    user.role = :admin
end

User.find_or_create_by!(email: "user@speedpastes.org") do |user|
    user.username = "user"
    user.password = "hunter2"
    user.password_confirmation = "hunter2"
    user.bio = "Seeded regular user. Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    user.link = "https://speedpastes.org"
    user.role = :user
end

InviteCode.find_or_create_by!(code: "INVITE") do |invite|
    invite.max_uses = 100
    invite.uses_count = 0
    invite.created_by = User.find_by(username: "admin")
end

# Create a bunch of pastes
user = User.find_by(username: "user")
admin = User.find_by(username: "admin")
100.times do |i|
    Paste.create! do |paste|
        paste.title = "Sample Paste #{i}"
        paste.body = "This is the body of sample paste number #{i}.\n" * 5
        paste.user = i % 2 == 1 ? user : admin
        paste.visibility = i % 2 == 0 ? :open : :unlisted
        paste.tags = [ "test_tag", "tag_#{i}" ]
    end
end

# Create some more users
100.times do |i|
    User.find_or_create_by!(email: "user#{i}@speedpastes.org") do |user|
        user.username = "user#{i}"
        user.email = "user#{i}@speedpastes.org"
        user.password = "hunter2"
        user.password_confirmation = "hunter2"
        user.bio = "This is the bio of user#{i}. Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        user.link = "https://speedpastes.org/u/user#{i}"
    end
end
