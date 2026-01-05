# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
if Rails.env.production? && ENV["ALLOW_PROD_SEED"] != "true"
    puts "Production seeding is disabled. Set ALLOW_PROD_SEED=true to enable."
    exit
end

env_seed = Rails.root.join("db", "seeds", "#{rails.env.downcase}.rb")

if env_seed.exist?
    puts "Loading seeds for #{rails.env} environment..."
    load env_seed
else
    puts "No seeds for #{rails.env} environment."
end
