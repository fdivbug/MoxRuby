require 'hpricot'
require 'open-uri'
require 'benchmark'
require 'RMagick'
require 'base64'
require 'pp'

class ExpansionDoesNotExistError < RuntimeError ; end
class CardNotFoundInOracleError < RuntimeError ; end

def load_expansion(expansion)
  puts "Loading cards from #{expansion.name}."
  Benchmark.bm(10) do |b|
    b.report("Gatherer") do
      doc = Hpricot(open(expansion.gatherer_url))
      rows = doc.search "table[@class='checklist']/tr[@class='cardItem']"
      unless rows.size == expansion.cards.size # The cards that were in a given expansion shouldn't change much.  Or, really, ever.
        expansion.printings = []
        rows.each do |tr|
          number = tr.at("td[@class='number']").inner_html.strip
          # Perform Unicode-to-ASCII name conversions here.
          name = tr.at("a[@class='nameLink']").inner_html.strip
          multiverse_id = tr.at("a[@class='nameLink']")[:href].split("=").last.strip
          artist = tr.at("td[@class='artist']").inner_html.strip
          rarity = tr.at("td[@class='rarity']").inner_html.strip

          card = Card.find_or_create_by_name(name)
          p = Printing.new
          p.number = number
          p.multiverse_id = multiverse_id
          p.artist = Artist.find_or_create_by_name(artist)
          p.rarity = Rarity.find_by_abbreviation(rarity)
          p.card = card
          p.expansion = expansion
          p.save!
        end
      end
    end

    b.report("Oracle") do
      oracle_cards = {}
      File.open(File.join(Rails.root, "lib", "oracle.txt")) do |file|
        paragraph = []
        file.each_line do |line|
          if line =~ /^$/
            oracle_cards[paragraph.first] = paragraph
            paragraph = []
          else
            paragraph << line.strip
          end
        end
      end
      expansion.cards.each do |card|
        para = oracle_cards[card.ascii_name].dup
        raise CardNotFoundInOracleError, card.name if para.nil?
        data = {}
        data.default = ""
        data[:name] = para.shift
        if para.first =~ /^[WUBRGX\d]+$/
          data[:cost] = para.shift
        end
        data[:types], data[:subtypes] = para.shift.split(" -- ")
        if para.first =~ /^[\d\*\+]*\/?[\d\*\+]+$/
          if para.first =~ /\//
            data[:power], data[:toughness] = para.shift.split("/")
          else
            data[:toughness] = para.shift # Just treat Planeswalkers' loyalty as their toughness.
          end
        end
        data[:printings] = para.pop # Printings comes off the end of the card text...
        if para.last =~ /^\[.*\]$/
          phys_attrs = para.pop # ... optionally followed by color indicators, front/back facing, and transformation info.
          phys_attrs.gsub!(/[\[\]]/, '') # Strip the brackets surrounding the text.
          md = phys_attrs.match(/(\S+) color indicator\./)
          if md
            ci = ""
            md[1].split('/').each do |c|
              case c
              when 'White'
                ci += 'W'
              when 'Blue'
                ci += 'U'
              when 'Black'
                ci += 'B'
              when 'Red'
                ci += 'R'
              when 'Green'
                ci += 'G'
              end
            end
            data[:color_indicator] = ci
          end
          md = phys_attrs.match(/(Front|Back) face\./)
          if md
            data[:face] = md[1].downcase
          end
          md = phys_attrs.match(/Transforms into (.*?)\./)
          if md
            tc = Card.find_by_name(md[1])
            data[:transforms_into_id] = tc.id
          end
        end
        data[:text] = para.join "\n"
        
        card.mana_cost = data[:cost]
        card.text = data[:text]
        card.power = data[:power]
        card.toughness = data[:toughness]
        card.color_indicator = data[:color_indicator]
        card.face = data[:face]
        card.transforms_into_id = data[:transforms_into_id]
        card.supertypes = []
        card.types = []
        card.subtypes = []
        data[:types].split.each do |x|
          if x =~ /^(Basic|Legendary|Ongoing|Snow|World)$/
            card.supertypes << Supertype.find_or_create_by_name(x)
          else
            card.types << Type.find_or_create_by_name(x)
          end
        end
        if data[:subtypes]
          data[:subtypes].split.each {|x| card.subtypes << Subtype.find_or_create_by_name(x) }
        end
        card.save!
      end
    end
  end
  puts "#{expansion.cards.size} cards processed."
end

def update_prices(expansion)
  next_url = expansion.scg_url
  cards = []
  while next_url != ""
    puts next_url
    doc = Hpricot(open(next_url))
    doc.search("/table[1]/tr").each do |row|
      next unless row.search("/td[@class='deckdbbody']|[@class='deckdbbody2']").size >= 8
      card = {}
      card[:name]     = row.at("td[1]/b/a").inner_text.strip
      card[:category] = row.at("td[2]/a").inner_text.strip
      card[:price]    = row.at("td[9]").inner_text.strip.sub('$', '').to_f
      cards << card
    end
    a = doc.at("/table[1]/tr[2]/td[1]/a[text()='- Next>>']")
    if a
      next_url = a['href']
    else
      next_url = ""
    end
  end
  cards.each do |c|
    card = Card.find_by_name c[:name]
    unless card
      STDERR.puts "Not found: #{c[:name]}"
      next
    end
    printing = card.printings.detect {|x| x.expansion == expansion }
    case c[:category]
    when /\(Foil\)/
      printing.foil_price = c[:price]
    else
      printing.price = c[:price]
    end
    printing.save!
  end
end

def create_images(expansion)
  puts "Downloading and re-borderizing #{expansion.printings.size} images for #{expansion.name}."

  Dir.mkdir(expansion.image_dir) unless File.directory?(expansion.image_dir)

  border_img = Magick::Image.read(expansion.border_image_path).first

  expansion.printings.each do |p|
    img_data64 = Base64.encode64(open(p.gatherer_image_url).read)
    src_img = Magick::Image.read_inline(img_data64).first

    case expansion.border
    when 'alpha' # Alpha images from Gatherer have different dimensions.
      cropped_img = src_img.crop(13, 13, 200, 285)
    else
      cropped_img = src_img.crop(11, 12, 200, 285)
    end

    dest_img = border_img.composite(cropped_img, 11, 12, Magick::OverCompositeOp)
    dest_img.write(p.image_path)
  end
end

namespace :expansion do
  EXPANSIONS = YAML.load_file(File.join(Rails.root, "lib", "expansions.yml"))
  
  namespace :load do
    EXPANSIONS.each do |expansion|
      eval <<-CODE
        desc "Load the cards from #{expansion[:name]} into the database."
        task "#{expansion[:code].downcase}" => :environment do
          expansion = Expansion.find_or_create_by_code("#{expansion[:code]}")
          expansion.name       = "#{expansion[:name]}"
          expansion.code       = "#{expansion[:code]}"
          expansion.border     = "#{expansion[:border]}"
          expansion.directory  = expansion[:directory] || expansion[:code]
          expansion.scg_number = expansion[:scg_number]
          expansion.scg_name   = expansion[:scg_name]
          expansion.save!
          load_expansion(expansion)
        end
      CODE
    end
  end

  namespace :update_prices do
    EXPANSIONS.each do |expansion|
      eval <<-CODE
        desc "Update the prices for #{expansion[:name]}."
        task "#{expansion[:code].downcase}" => :environment do
          expansion = Expansion.find_by_code("#{expansion[:code]}")
          raise ExpansionDoesNotExistError unless expansion
          update_prices(expansion)
        end
      CODE
    end
  end

  namespace :images do
    namespace :create do
      EXPANSIONS.each do |expansion|
        eval <<-CODE
          desc "Download and re-borderize card images for #{expansion[:name]}."
          task "#{expansion[:code].downcase}" => :environment do
            expansion = Expansion.find_by_code("#{expansion[:code]}")
            raise ExpansionDoesNotExistError unless expansion
            create_images(expansion)
          end
        CODE
      end
    end
  end
end
