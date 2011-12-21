#!/usr/bin/ruby -w

=begin
    A small Ruby script to tag mp3 files in the current directory.
    Copyright (C) 2011 David T. Sadler

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'rubygems'
require 'bundler/setup'

require 'highline/import'
require 'mp3info'

module Mp3Tagger
  def self.run
    loop do
      ask_for_filename_format
      ask_for_common_tags
      ask_for_track_info
      display_summary
      break if agree('Does this look correct? ', true)
    end
    tag_files
  end

private
  @common_tags = {}
  @track_info = []
  @pad_by = nil
  @filename_format = nil
  @parse_info = nil

  def self.ask_for_filename_format
    @filename_format = ask('Filename format? ') { |q| q.default = @filename_format }
    @parse_info = build_parse_info(@filename_format)
  end

  def self.ask_for_common_tags
    @common_tags[:artist] = ask_for_common_artist unless @parse_info['<artist>'][:use_from_fn] 
    @common_tags[:album] = ask_for_common_album unless @parse_info['<album>'][:use_from_fn] 
    @common_tags[:year] = ask_for_common_year unless @parse_info['<year>'][:use_from_fn] 
    @common_tags[:genre] = ask_for_common_genre unless @parse_info['<genre>'][:use_from_fn] 
  end

  def self.ask_for_common_artist
    ask('Artist? ') { |q| q.default = @common_tags[:artist] }
  end

  def self.ask_for_common_album
    ask('Album? ') { |q| q.default = @common_tags[:album] }
  end

  def self.ask_for_common_year
    ask('Year? ') do |q| 
      q.default = @common_tags[:year]
      q.validate = lambda { |answer| answer == '' || answer =~ /^\d{4}$/ }
      q.responses[:not_valid] = 'A 4 digit year must be entered'
    end
  end

  def self.ask_for_common_genre
    ask('Genre? ') do |q| 
      q.default = @common_tags[:genre]
      q.validate = lambda { |answer| answer == '' || Mp3Info::GENRES.include?(answer) }
      q.responses[:not_valid] = "Genre must be one of the following: \"#{Mp3Info::GENRES.join('","')}\""
    end
  end

  def self.ask_for_track_info
    mp3files.each_with_index do |filename, index|
      @track_info[index] ||= {}
      @track_info[index] = get_default_track_info(@track_info[index], filename) 
      say "Info for <%= color('#{filename.gsub("'","\\\\'")}', :green) %>"
      @track_info[index][:artist] = ask_for_track_artist(@track_info[index][:artist]) unless @parse_info['<artist>'][:use_from_fn] or @common_tags[:artist] != ''
      @track_info[index][:album] = ask_for_track_album(@track_info[index][:album]) unless @parse_info['<album>'][:use_from_fn] or @common_tags[:album] != ''
      @track_info[index][:year] = ask_for_track_year(@track_info[index][:year]) unless @parse_info['<year>'][:use_from_fn] or @common_tags[:year] != ''
      @track_info[index][:genre] = ask_for_track_genre(@track_info[index][:genre]) unless @parse_info['<genre>'][:use_from_fn] or @common_tags[:genre] != ''
      @track_info[index][:tracknum] = ask_for_track_tracknum(@track_info[index][:tracknum], index) unless @parse_info['<tracknum>'][:use_from_fn]
      @track_info[index][:title] = ask_for_track_title(@track_info[index][:title]) unless @parse_info['<title>'][:use_from_fn]
    end
  end

  def self.get_default_track_info(default, filename)
    matches = @parse_info[:regexp].match(File.basename(filename,'.*'))
    track_info = {}
    track_info[:filename] = filename
    track_info[:artist] = default[:artist]
    track_info[:artist] = @common_tags[:artist] if @common_tags[:artist] != ''
    track_info[:artist] = matches[@parse_info['<artist>'][:pos]] if @parse_info['<artist>'][:pos] > 0 

    track_info[:album] = default[:album]
    track_info[:album] = @common_tags[:album] if @common_tags[:album] != ''
    track_info[:album] = matches[@parse_info['<album>'][:pos]] if @parse_info['<album>'][:pos] > 0 

    track_info[:year] = default[:year]
    track_info[:year] = @common_tags[:year] if @common_tags[:year] != ''
    track_info[:year] = matches[@parse_info['<year>'][:pos]] if @parse_info['<year>'][:pos] > 0 

    track_info[:genre] = default[:genre]
    track_info[:genre] = @common_tags[:genre] if @common_tags[:genre] != ''
    track_info[:genre] = matches[@parse_info['<genre>'][:pos]] if @parse_info['<genre>'][:pos] > 0 

    track_info[:tracknum] = default[:tracknum]
    track_info[:tracknum] = matches[@parse_info['<tracknum>'][:pos]] if @parse_info['<tracknum>'][:pos] > 0 

    track_info[:title] = default[:title]
    track_info[:title] = matches[@parse_info['<title>'][:pos]] if @parse_info['<title>'][:pos] > 0 

    track_info
  end

  def self.ask_for_track_artist(default)
    ask('Artist? ') do |q| 
      q.default = default
      q.validate = lambda { |answer| !answer.empty? }
      q.responses[:not_valid] = 'You must enter the artist\'s name'
    end
  end

  def self.ask_for_track_album(default)
    ask('Album? ') do |q| 
      q.default = default
      q.validate = lambda { |answer| !answer.empty? }
      q.responses[:not_valid] = 'You must enter the album name'
    end
  end

  def self.ask_for_track_year(default)
    ask('Year? ') do |q| 
      q.default = default
      q.validate = /^\d{4}$/
      q.responses[:not_valid] = 'A 4 digit year must be entered'
    end
  end

  def self.ask_for_track_genre(default)
    ask('Genre? ') do |q| 
      q.default = default
      q.validate = lambda { |answer| Mp3Info::GENRES.include?(answer) }
      q.responses[:not_valid] = "Genre must be one of the following: \"#{Mp3Info::GENRES.join('","')}\""
    end
  end

  def self.ask_for_track_tracknum(default, index)
    ask('Track Number? ') do |q| 
      q.default = default ? default : (index + 1).to_s
      q.validate = /^\d+$/
      q.responses[:not_valid] = 'Non digit character was entered'
    end
  end

  def self.ask_for_track_title(default)
    ask('Title? ') do |q| 
      q.default = default
      q.validate = lambda { |answer| !answer.empty? }
      q.responses[:not_valid] = 'You must enter a title'
    end
  end

  def self.display_summary
    @track_info.each do |info|
      say "#{summary(info[:filename], :green)}"
      say "#{summary(info[:year], :blue)} #{summary(info[:genre], :blue)} #{summary(info[:artist], :blue)} #{summary(info[:album], :blue)} #{summary(info[:tracknum], :blue)}-#{summary(info[:title], :blue)} #{summary(new_filename(info), :red)}"
    end
  end

  def self.summary(info, color)
    "<%= color('[#{info.gsub("'","\\\\'")}]', :#{color}) %>"
  end

  def self.tag_files
    @track_info.each do |info|
      say "Tagging <%= color('#{info[:filename].gsub("'","\\\\'")}', :green) %>"

      mp3 = Mp3Info.open(info[:filename])
      mp3.removetag1
      mp3.removetag2
      mp3.flush
      mp3.tag2.TPE1 = info[:artist]
      mp3.tag2.TALB = info[:album]
      mp3.tag2.TYER = info[:year]
      mp3.tag2.TCON = info[:genre]
      mp3.tag2.TIT2 = info[:title]
      mp3.tag2.TRCK = info[:tracknum].to_i
      mp3.close

      File.rename(info[:filename], new_filename(info))
    end
  end

  def self.new_filename(info)
    padded_track_number = "%0#{pad_by(info[:album])}d" % info[:tracknum]
    "#{padded_track_number}-#{info[:title]}.mp3"
  end

  def self.mp3files
    Dir.glob('*.mp3').sort
  end

  def self.pad_by(album)
    @pad_by ||= @track_info.select{|info|info[:album]===album}.size.to_s.split(//).size
    @pad_by = 2 if @pad_by < 2
    @pad_by  
  end

  def self.build_parse_info(format)
    parse_info = {
      '<title>' => {
        :regexp => '(.*?)',
        :pos => 0,
        :use_from_fn => false
      },

      '<artist>' => {
        :regexp => '(.*?)',
        :pos => 0,
        :use_from_fn => false
      },

      '<album>' => {
        :regexp => '(.*?)',
        :pos => 0,
        :use_from_fn => false
      },

      '<year>' => {
        :regexp => '(.*?)',
        :pos => 0,
        :use_from_fn => false
      },

      '<genre>' => {
        :regexp => '(.*?)',
        :pos => 0,
        :use_from_fn => false
      },

      '<tracknum>' => {
        :regexp => '([^ ]*?)',
        :pos => 0,
        :use_from_fn => false
      }
    }

    template = format.dup
    # Constrain the expression to match the whole string and escape characters that have special meaning in regexps.
    template = '^' << Regexp.escape(template) << '$'
    # Find the markers, record their relative positions and replace them in the final expression.
    format.scan(Regexp.new(parse_info.keys.join('|'))).each_with_index do |marker, index| 
      parse_info[marker][:pos] = index + 1 
      parse_info[marker][:use_from_fn] = true
    end
    parse_info.each { |key, value| template.gsub!(key, value[:regexp]) }

    parse_info[:regexp] = Regexp.compile(template, Regexp::IGNORECASE, "U")

    return parse_info
  end
end

Mp3Tagger.run
