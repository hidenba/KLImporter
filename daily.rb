# -*- coding: utf-8 -*-
require 'kl_importer'

module Importer
  class Daily < Kl
    def daily_contents
      daily = ActiveSupport::OrderedHash.new
      @contents.each do |c|
        c.records.each do |r|
          daily[r.date] ||= []
          daily[r.date] += r.work_times
        end
      end
      daily.each do |d,t|
        st = t.sort { |a,b| a.start <=> b.start }
        daily[d] = { :start=>st.first.start, :end=>st.last.end}
      end
      daily
    end

    def to_csv(file_name, header=[])
      csv = FasterCSV.open(file_name, "w")
      csv << header unless header.empty?
      if block_given?
        @date.beginning_of_month.upto(@date.end_of_month) do |date|
          if t=daily_contents[date]
            csv << yield(date,t[:start],t[:end],KLTime::total_time(t[:start],t[:end]))
          else
            csv << yield(date,nil,nil,nil)
          end
        end
      end
      csv.close
      csv
    end
  end

  module KLTime
    class << self
      def total_time(s,e)
        ((e-s)/3600) - (s.hour < 12 && e.hour > 13 ? 1 : 0)
      end
    end
  end
end

if $0 == __FILE__
  WDAY = %w(日 月 火 水 木 金 土)
  require 'optparse'
  OPTS = {}
  OptionParser.new do |opt|
    opt.on('-i VAL:入力となるCSVファイルを指定する') {|v| OPTS[:i] = v }
    opt.on('-y VAL:対象年を指定する') {|v| OPTS[:y] = v }
    opt.on('-m VAL:対象月を指定する') {|v| OPTS[:m] = v }
    opt.on('-o VAL:出力ファイルを指定する') {|v| OPTS[:o] = v }
    opt.on('-n VAL:出力対象者を指定する（指定がない場合は全員出力）') {|v| OPTS[:n] = v }
    opt.parse!
    if OPTS.empty?
      puts opt.help
      exit 1
    end
  end

  in_csv = FasterCSV.read(OPTS[:i])
  users = {}
  in_csv.each do |line|
    user_name = line[4]
    if OPTS[:n].nil? || OPTS[:n] == user_name
      users[user_name] ||= []
      users[user_name] << line 
    end
  end
  users.delete(nil)

  users.each do |user_name, csv_line|
    dl = Importer::Daily.new(in_csv.first, csv_line, "#{OPTS[:y]}/#{OPTS[:m]}")
    dl.to_csv("#{OPTS[:o]}_to_esm(#{user_name})") do |d,s,e,t|
      if s.nil?
        [d.strftime("%Y/%m/%d"),WDAY[d.wday]]
      else
        [d.strftime("%Y/%m/%d"),WDAY[d.wday],s.hour,s.min,e.hour,e.min,t.to_i,((t-t.to_i)*60).to_i]
      end

    end
    dl.to_csv("#{OPTS[:o]}_to_is(#{user_name})") do |d,s,e,t|
      if s.nil?
        [d.strftime("%d"),WDAY[d.wday]]
      else
        [d.strftime("%d"),WDAY[d.wday],s.strftime("%H:%M"),e.strftime("%H:%M")]
      end
    end
  end
  
end

