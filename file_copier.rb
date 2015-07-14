#coding: utf-8
require 'rubygems'
require 'hpricot'
require 'open-uri'
require "net/http"
require 'sqlite3'
require 'fileutils.rb'

$name = ARGV.join(" ")

$db = SQLite3::Database.new "berserk.db"
puts $db.get_first_value 'SELECT SQLITE_VERSION()'

puts $name
$stm = $db.prepare ("SELECT fname FROM Card WHERE edition = ?")
$stm.bind_params($name)
$row = $stm.execute

if $row
  Dir.mkdir("#{$name}") unless Dir.exist?("#{$name}")

  $row.each do |el|
    puts el
    FileUtils.cp("images/#{el.first}", "#{$name}/#{el.first}")
    FileUtils.rm("images/#{el.first}")
  end
end
$stm.close