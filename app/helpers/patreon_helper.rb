module PatreonHelper
  def patron_status_to_readable(status)
      case status
      when "active_patron"
          "Active"
      when "former_patron"
          "Expired"
      else
          "Not a supporter"
      end
  end
end
