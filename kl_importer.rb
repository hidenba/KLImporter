# -*- coding: utf-8 -*-
require 'rubygems'
require 'bundler'
Bundler.setup
require 'fastercsv'
require 'active_support'

class KLImporter
  attr_reader :contents
  def initialize(header,line_data,yyyymm)
    @contents = []
    d = Splitter::date(yyyymm, header)
    line_data.each do |l|
      content, records = Splitter::split(l)
      rd = []
      Splitter::record(records).each_with_index do |r,ix|
        rd << WorkRecord.new(r,d[ix])
      end
      @contents << WorkContent.new(content,rd)
    end
  end

  def to_csv(file_name, header=[])
    csv = FasterCSV.open(file_name, "w")
    csv << header unless header.empty?
    if block_given?
      @contents.each do |c|
        c.records.each do |rs|
          rs.work_times.each do |t|
            csv << yield(c,t)
          end
        end
      end
    end
    csv.close
    csv
  end
end

class WorkContent
  TYPE_TABLE = { 
    '計画 ( 設計 )'=>1,
    '開発'=>2,
    'テスト'=>3,
    'デモ ( 準備、実施 )'=>4,
    'デバッグ'=>5,
    '保守'=>6,
    'メール・KL チェック'=>7,
    '会議'=>8,
    '移動'=>9,
    '教育'=>10,
    '事務 ( 報告 )'=>11,
    'その他'=>12,
  }
  attr_accessor :task_id,:todo_name,:type,:detail,:records,:type_code
  def initialize(content,records)
    @task_id, @todo_name, @type, @detail = content
    @records = records.delete_if { |v| v.empty? } 
    @type_code = TYPE_TABLE[@type]
  end
end

class WorkRecord
  WorkTime = Struct.new(:start, :end)
  NAMES = ActiveSupport::OrderedHash.new
    NAMES[:morning] = %w[10:00 10:30]
    NAMES[:first]   = %w[10:30 12:30]
    NAMES[:second]  = %w[13:30 15:30]
    NAMES[:third]   = %w[16:00 18:00]
    NAMES[:evening] = %w[18:00 18:30]
    NAMES[:orver_time] = %w[18:30]

  attr_reader :date
  def initialize(record,date)
    NAMES.keys.each_with_index do |sym,i|
      add_method(sym, record[i])
    end
    @date = date
  end

  def empty?
    !NAMES.keys.map { |n| eval("#{n.to_s}?") }.include?(true)
  end

  def work_times
    times=[]
    NAMES.each do |k,v|
      if eval("#{k.to_s}?")
        e = k == :orver_time ? KLTime.orvertime(@date,v.last,orver_time) : KLTime.make_time(@date,v.last)
        times << WorkTime.new(KLTime.make_time(@date,v.first), e) 
      end
    end
    times
  end

  private
  def add_method(sym, val)
    v = !val.nil? && !val.empty?
    instance_eval("def #{sym.to_s}?; #{v}; end")
    instance_eval("def #{sym.to_s}; #{val}; end")
  end
end

module KLTime
  class << self
    def make_time(date, time_str)
      hh,mm = time_str.split(":")
      Time.mktime(date.year, date.month, date.day, hh.to_i, mm.to_i)
    end

    def orvertime(date, time_str, orver_min)
      dt = KLTime.make_time(date, time_str)
      dt + (orver_min*60)
    end
  end
end

module Splitter
  RECORD_OFFSET = 6
  DATE_OFFSET = 5
  CONTENT_SIZE = 4
  class << self
    def split(line)
      [line.shift(CONTENT_SIZE), line[1..line.size]]
    end
    def record(time_box)
      time_box.each_slice(RECORD_OFFSET).select { |t| t.size == RECORD_OFFSET}
    end
    def date(yymm, line)
      line[DATE_OFFSET..line.size].compact.delete_if { |v| v.empty? }.map{ |v|  Date.parse("#{yymm}/#{v}")}
    end
  end
end

if $0 == __FILE__
  require 'optparse'
  OPTS = {}
  OptionParser.new do |opt|
    opt.on('-i VAL:入力となるCSVファイルを指定する') {|v| OPTS[:i] = v }
    opt.on('-y VAL:対象年を指定する') {|v| OPTS[:y] = v }
    opt.on('-m VAL:対象月を指定する') {|v| OPTS[:m] = v }
    opt.on('-o VAL:出力ファイルを指定する') {|v| OPTS[:o] = v }
    opt.parse!
    if OPTS.empty?
      puts opt.help
      exit 1
    end
  end

  csv_data = FasterCSV.read(OPTS[:i])
  users = {}
  csv_data.each do |line|
    user_name = line[4]
    users[user_name] ||= []
    users[user_name] << line
  end
  users.delete(nil)

  HEADER = %w[taskId TODOタイトル TODO内容 TODO開始日付 TODO終了日付 TODOステータス TODO評価、TODO中断・中止理由 作業ログ開始日付 作業ログ終了日付 作業ログ種類 作業ログ内容]
  DATE_FORMAT = "%Y/%m/%d %H:%M:%S"
  users.each do |user_name, csv_line|
    task_id = csv_data.first
    kl = KLImporter.new(task_id, csv_line, "#{OPTS[:y]}/#{OPTS[:m]}")
    kl.to_csv("#{OPTS[:o]}(#{user_name})", HEADER) do |c, t|
      st = t.start.strftime(DATE_FORMAT)
      et = t.end.strftime(DATE_FORMAT)
      [c.task_id, c.todo_name, '', '', '', '', '', st, et, c.type_code, c.detail]
    end
  end

end
