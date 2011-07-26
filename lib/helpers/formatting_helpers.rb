module StereosupersonicPlugin
  module FormattingHelpers

    def is_float?(value)
       ((value.to_f * 100) % 100) > 0
    end

    def format_date(date)
      date.strftime '%d.%m.%Y' if date
    end

    def format_datetime(date)
      date.strftime '%d.%m.%Y %H:%M' if date
    end

    def format_currency(price)
      sprintf("&euro; %.2f", price.parse_international_float).sub ".", "," unless price.blank?
    end

    def format_currency_plain(price)
      sprintf("€ %.2f", price.parse_international_float).sub(".", ",") unless price.blank?
    end

    def format_currency_without_symbol(price)
      sprintf("%.2f", price.parse_international_float).sub(".", ",") unless price.blank?
    end
    
    def format_float(numb)
      sprintf("%.1f", numb.parse_international_float).sub(".", ",") unless numb.blank?
    end

    def format_percentage(percent)
      sprintf('%.2f', percent.parse_international_float).sub(/(0{1,2}|\.00)$/, '') + " %" unless percent.blank?
    end

  end
end

ApplicationHelper.send(:include, StereosupersonicPlugin::FormattingHelpers)