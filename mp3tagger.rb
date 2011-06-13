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

  def self.ask_for_common_tags
    @common_tags[:artist] = ask('Artist? ') do |q| 
      q.default = @common_tags[:artist]
      q.validate = lambda { |answer| !answer.empty? }
      q.responses[:not_valid] = 'You must enter the artist\'s name'
    end
    @common_tags[:album] = ask('Album? ') do |q| 
      q.default = @common_tags[:album]
      q.validate = lambda { |answer| !answer.empty? }
      q.responses[:not_valid] = 'You must enter the album name'
    end
    @common_tags[:year] = ask('Year? ') do |q| 
      q.default = @common_tags[:year]
      q.validate = /^\d{4}$/
      q.responses[:not_valid] = 'A 4 digit year must be entered'
    end
    @common_tags[:genre] = ask('Genre? ', Mp3Info::GENRES) { |q| q.default = @common_tags[:genre] }
  end

  def self.ask_for_track_info
    mp3files.each_with_index do |file, index|
      @track_info[index] ||= {}
      @track_info[index][:file] = file
      say "Info for <%= color('#{file}', :green) %>"
      @track_info[index][:tracknum] = ask('Track Number? ') do |q| 
        q.validate = /^\d+$/
        q.default = @track_info[index][:tracknum] ? @track_info[index][:tracknum] : (index + 1).to_s
        q.responses[:not_valid] = 'Non digit character was entered'
      end
      @track_info[index][:title] = ask('Title? ') do |q| 
        q.default = @track_info[index][:title] 
        q.validate = lambda { |answer| !answer.empty? }
        q.responses[:not_valid] = 'You must enter a title'
      end
    end
  end

  def self.display_summary
    say "Artist: <%= color('#{@common_tags[:artist]}', :blue) %>"
    say "Album : <%= color('#{@common_tags[:album]}', :blue) %>"
    say "Year  : <%= color('#{@common_tags[:year]}', :blue) %>"
    say "Genre : <%= color('#{@common_tags[:genre]}', :blue) %>"
    @track_info.each do |info|
      say "<%= color('#{info[:file]}', :green) %> -> <%= color('#{new_filename(info)}', :red) %>"
    end
  end

  def self.tag_files
    @track_info.each do |info|
      say "Tagging <%= color('#{info[:file]}', :green) %>"

      mp3 = Mp3Info.open(info[:file])
      mp3.removetag1
      mp3.removetag2
      mp3.flush
      mp3.tag2.TPE1 = @common_tags[:artist]
      mp3.tag2.TALB = @common_tags[:album]
      mp3.tag2.TYER = @common_tags[:year]
      mp3.tag2.TCON = @common_tags[:genre]
      mp3.tag2.TIT2 = info[:title]
      mp3.tag2.TRCK = info[:tracknum].to_i
      mp3.close

      File.rename(info[:file], new_filename(info))
    end
  end

  def self.new_filename(info)
    padded_track_number = "%0#{pad_by}d" % info[:tracknum]
    "#{padded_track_number}-#{info[:title]}.mp3"
  end

  def self.mp3files
    Dir.glob('*.mp3').sort
  end

  def self.pad_by
    @pad_by ||= @track_info.size.to_s.split(//).size
    @pad_by = 2 if @pad_by < 2
    @pad_by
  end

end

Mp3Tagger.run
