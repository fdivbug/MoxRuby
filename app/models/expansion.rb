require 'cgi'

class Expansion < ActiveRecord::Base
  attr_accessible :border, :name, :release_date

  def scg_url
    "http://sales.starcitygames.com/spoiler/display.php?s[#{scg_name}]=#{scg_number}&g[G1]=NM%2FM&foil=all&for=no&display=4&numpage=200&action=Show+Results"
  end

  def gatherer_url
    "http://gatherer.wizards.com/Pages/Search/Default.aspx?output=checklist&set=[%22#{CGI.escape(name)}%22]"
  end

end
