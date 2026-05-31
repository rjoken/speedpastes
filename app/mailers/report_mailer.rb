class ReportMailer < ApplicationMailer
  Report = Struct.new(:url, :details, :reply_to, keyword_init: true)

  def report(shortcode:, details:, reply_to: nil)
    @report = Report.new(
      url: short_paste_url(shortcode),
      details: details,
      reply_to: reply_to
    )

    mail_opts = {
      to: ENV["REPORT_EMAIL"],
      subject: "Paste report: #{shortcode}"
    }
    mail_opts[:reply_to] = @report.reply_to if @report.reply_to.present?

    mail(**mail_opts)
  end

  private

  def short_paste_url(shortcode)
    "#{ENV['ROOT_URL']}/#{shortcode}"
  end
end
