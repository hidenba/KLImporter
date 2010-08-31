# -*- coding: utf-8 -*-
require "daily"

describe Importer::Daily do 
  context ".daily" do 
    before do 
      @header = ['i', 'd', 't', 'd', 'n', "2","","","","","","3","","","","","","4","","","","""",]
      @line_data = [%w[task_id todo_name type detail name o o o o o 1 o o o o o 2],
                  %w[task_id todo_name type detail name o o o o o 3 o o o o o 4]]
      @importer = Importer::Daily.new(@header, @line_data, "2010/06")
    end

    it "日毎に開始終了時刻が取得出来ていること" do 
      actual = @importer.daily_contents
      actual.should have(2).dayliy_content
      actual[Date.parse("2010/06/02")].should_not be_nil
      actual[Date.parse("2010/06/02")][:start].should eql Time.mktime(2010,6,2,10)
      actual[Date.parse("2010/06/02")][:end].should eql Time.mktime(2010,6,2,18,33)

      actual[Date.parse("2010/06/03")].should_not be_nil
      actual[Date.parse("2010/06/03")][:start].should eql Time.mktime(2010,6,3,10)
      actual[Date.parse("2010/06/03")][:end].should eql Time.mktime(2010,6,3,18,34)
    end
  end

  context ".to_csv" do 
    before do 
      @header = ['i', 'd', 't', 'd', 'n', "2","","","","","","3","","","","","""",]
      @line_data = [%w[task_id todo_name type detail name o o o o o 10 o o o o o 20]]
      File.stub!(:open).and_return(StringIO.new)
      @target = Importer::Daily.new(@header, @line_data, "2010/06")
    end

    it "CSVが出力されていること" do 
      csv_data =  @target.to_csv("test.csv") do |d,s,e,t|
        [d.to_s,s.to_s,e.to_s,t]
      end
      actual = csv_data.string.split("\n")
      actual.should have(30).lines
      line_data = actual[1].split(",")
      line_data[0].should eql "2010-06-02"
      line_data[1].should eql "Wed Jun 02 10:00:00 +0900 2010"
      line_data[2].should eql "Wed Jun 02 18:40:00 +0900 2010"
      line_data[3].to_f.should be_close(7.6, 0.1)
    end

    it "ヘッダが出力されていること" do 
      csv_data =  @target.to_csv("test.csv", %w[a b c d])
      actual = csv_data.string.split("\n")
      actual.should have(1).lines
      line_data = actual.first.split(",")
      line_data[0].should eql "a"
      line_data[1].should eql "b"
      line_data[2].should eql "c"
      line_data[3].should eql "d"
    end
  end

end

describe Importer::KLTime do 
  before do 
    @end = Time.mktime(2010,6,8,19,30)
  end
  context ".total_time" do
    it { Importer::KLTime.total_time(Time.mktime(2010,6,8,10),@end).should eql 8.5}
    it { Importer::KLTime.total_time(Time.mktime(2010,6,8,13),@end).should eql 6.5}
  end
end
