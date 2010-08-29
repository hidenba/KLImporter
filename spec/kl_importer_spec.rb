# -*- coding: utf-8 -*-
require "kl_importer"

describe KLImporter do 
  context ".new" do 
    it "必要なコンテンツが生成されていること" do 
      header = ['i', 'd', 't', 'd', 'n', "2","","","","","","3","","","","","","4","","","","""",]
      line_data = [%w[task_id todo_name type detail name o o o o o 1 o o o o o 2],
                  %w[task_id todo_name type detail name o o o o o 3 o o o o o 4]]
      actual = KLImporter.new(header, line_data, "2010/06")
      actual.contents.should have(2).content
      actual.contents.first.records.should have(2).record
      actual.contents.last.records.should have(2).record
    end
  end

  context ".to_csv" do 
    before do 
      @header = ['i', 'd', 't', 'd', 'n', "2","","","","","","3","","","","","""",]
      @line_data = [%w[task_id todo_name type detail name o o o o o 10 o o o o o 20]]
    end

    it "CSVが出力されていること" do 
      File.stub!(:open).and_return(StringIO.new)
      target = KLImporter.new(@header, @line_data, "2010/06")
      csv_data =  target.to_csv("test.csv") do |c,t|
        [c.task_id,c.todo_name,c.type,c.detail,t.start.to_s,t.end.to_s]
      end
      actual = csv_data.string.split("\n")
      actual.should have(12).lines
      line_data = actual.first.split(",")
      line_data[0].should eql "task_id"
      line_data[1].should eql "todo_name"
      line_data[2].should eql "type"
      line_data[3].should eql "detail"
<<<<<<< HEAD
      line_data[4].should eql "Wed Jun 02 10:00:00 +0900 2010"
      line_data[5].should eql "Wed Jun 02 10:30:00 +0900 2010"
=======
      line_data[4].should eql "2010-06-02T10:00:00+00:00"
      line_data[5].should eql "2010-06-02T10:30:00+00:00"
>>>>>>> c9da87aa3daa7a101455db925941918a183b87e8
    end

    it "ヘッダが出力されていること" do 
      File.stub!(:open).and_return(StringIO.new)
      target = KLImporter.new(@header, @line_data, "2010/06")
      csv_data =  target.to_csv("test.csv", %w[a b c d])
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

describe Splitter do
  context ".split" do 
    it "コンテンツ部分とレコード部分が取得できていること" do 
      actual = Splitter.split(%w[task_id todo_name type detail name M o o o o E M o o o o E])
      actual.first.should eql %w[task_id todo_name type detail]
      actual.last.should eql %w[M o o o o E M o o o o E]
    end
  end

  context ".record" do 
    it "6カラムごとに取得できていること"  do 
      actual = Splitter.record(%w[M 1 2 3 4 E MM 11 22 33 44 EE])
      actual.should_not be_nil
      actual.should have(2).items
      actual.first.should == %w[M 1 2 3 4 E]
      actual.last.should == %w[MM 11 22 33 44 EE]
    end
    it "半端がある場合は切り捨てられること"  do 
      actual = Splitter.record(%w[M 1 2 3 4 E MM 11 22 33 44 EE aa dd])
      actual.should have(2).items
    end
    it "6カラムに満たない場合はからの配列が得られること"  do 
      actual = Splitter.record(%w[M 1 2 3 4 ])
      actual.should be_empty
    end
  end

  context ".date" do 
    before do 
      @yymm = "2010/06"
    end
    it "日付の配列が取得できていること" do 
      actual = Splitter.date(@yymm, ['i', 'd', 't', 'd', 'n', "2","","","","","","3","","","","","","4","","","","",""])
      actual[0].to_s.should eql "2010-06-02"
      actual[1].to_s.should eql "2010-06-03"
      actual[2].to_s.should eql "2010-06-04"
    end
  end
end

describe WorkRecord do 
  before do 
    @date = Date.parse("2010/06/08")
  end    
  context "すべてのコマに出席のばあい" do 
    before do 
      @target = WorkRecord.new(%w[o o o o o 10],@date)
    end    
    it "朝会に出席していること" do @target.morning?.should be_true  end
    it "１限目に出席していること" do @target.first?.should be_true  end
    it "２限目に出席していること" do @target.second?.should be_true  end
    it "３限目に出席していること" do @target.third?.should be_true  end
    it "夕会に出席していること" do @target.evening?.should be_true  end
    it "残業をしていること" do @target.orver_time?.should be_true  end
    it "empty?が偽を返していること" do   @target.empty?.should be_false  end
  end

  context "すべてのコマに欠席のばあい" do 
    before do 
      @target = WorkRecord.new(["","","","",""],@date)
    end    
    it "朝会に欠席していること" do @target.morning?.should be_false  end
    it "１限目に欠席していること" do @target.first?.should be_false  end
    it "２限目に欠席していること" do @target.second?.should be_false  end
    it "３限目に欠席していること" do @target.third?.should be_false  end
    it "夕会に欠席していること" do @target.evening?.should be_false  end
    it "残業をしていないこと" do @target.orver_time?.should be_false  end
    it "empty?が真を返していること" do   @target.empty?.should be_true  end
  end

  context "引数にnilのばあい" do 
    before do 
      @target = WorkRecord.new([nil,nil,nil,nil,nil],@date)
    end    

    it "朝会に欠席していること" do @target.morning?.should be_false  end
    it "１限目に欠席していること" do @target.first?.should be_false  end
    it "２限目に欠席していること" do @target.second?.should be_false  end
    it "３限目に欠席していること" do @target.third?.should be_false  end
    it "夕会に欠席していること" do @target.evening?.should be_false  end
    it "残業をしていないこと" do @target.orver_time?.should be_false  end
  end

  context "朝会の分だけ入っていた場合" do 
    before do 
      @target = WorkRecord.new(['o'],@date)
    end    

    it "朝会に出席していること" do @target.morning?.should be_true  end
    it "１限目に欠席していること" do @target.first?.should be_false  end
    it "２限目に欠席していること" do @target.second?.should be_false  end
    it "３限目に欠席していること" do @target.third?.should be_false  end
    it "夕会に欠席していること" do @target.evening?.should be_false  end
    it "残業をしていないこと" do @target.orver_time?.should be_false  end
    it "empty?が偽を返していること" do   @target.empty?.should be_false  end
  end

  context ".date" do 
    before do 
      @target = WorkRecord.new(%w[o o o o o 10], @date)
    end    
    it "日付が取得できていること" do @target.date.should eql @date  end
  end

  context ".work_time" do 

    it "開始と終了時刻が取得できていること" do 
      @target = WorkRecord.new(%w[o o o o o 10], @date)
      actual = @target.work_times
      actual.should have(6).worktime
    end

    it "朝会の開始終了時刻が取得出来ていること" do 
      @target = WorkRecord.new(['o','','','','',''], @date)
      actual = @target.work_times
<<<<<<< HEAD
      actual.first.start.to_s.should eql "Tue Jun 08 10:00:00 +0900 2010"
      actual.first.end.to_s.should eql "Tue Jun 08 10:30:00 +0900 2010"
=======
      actual.first.start.to_s.should eql "2010-06-08T10:00:00+00:00"
      actual.first.end.to_s.should eql "2010-06-08T10:30:00+00:00"
>>>>>>> c9da87aa3daa7a101455db925941918a183b87e8
    end

    it "1コマ目の開始終了時刻が取得出来ていること" do 
      @target = WorkRecord.new(['','o','','','',''], @date)
      actual = @target.work_times
      actual.should have(1).worktime
<<<<<<< HEAD
      actual.first.start.to_s.should eql "Tue Jun 08 10:30:00 +0900 2010"
      actual.first.end.to_s.should eql "Tue Jun 08 12:30:00 +0900 2010"
=======
      actual.first.start.to_s.should eql "2010-06-08T10:30:00+00:00"
      actual.first.end.to_s.should eql "2010-06-08T12:30:00+00:00"
>>>>>>> c9da87aa3daa7a101455db925941918a183b87e8
    end

    it "2コマ目の開始終了時刻が取得出来ていること" do 
      @target = WorkRecord.new(['','','o','','',''], @date)
      actual = @target.work_times
      actual.should have(1).worktime
      actual.first.start.to_s.should eql "Tue Jun 08 13:30:00 +0900 2010"
      actual.first.end.to_s.should eql "Tue Jun 08 15:30:00 +0900 2010"
    end

    it "3コマ目の開始終了時刻が取得出来ていること" do 
      @target = WorkRecord.new(['','','','o','',''], @date)
      actual = @target.work_times
      actual.should have(1).worktime
      actual.first.start.to_s.should eql "Tue Jun 08 16:00:00 +0900 2010"
      actual.first.end.to_s.should eql "Tue Jun 08 18:00:00 +0900 2010"
    end

    it "夕会の開始終了時刻が取得出来ていること" do 
      @target = WorkRecord.new(['','','','','o',''], @date)
      actual = @target.work_times
      actual.should have(1).worktime
      actual.first.start.to_s.should eql "Tue Jun 08 18:00:00 +0900 2010"
      actual.first.end.to_s.should eql "Tue Jun 08 18:30:00 +0900 2010"
    end
    it "残業の開始終了時刻が取得出来ていること" do 
      @target = WorkRecord.new(['','','','','','35'], @date)
      actual = @target.work_times
      actual.should have(1).worktime
      actual.first.start.to_s.should eql "Tue Jun 08 18:30:00 +0900 2010"
      actual.first.end.to_s.should eql "Tue Jun 08 19:05:00 +0900 2010"
    end
  end
end  

<<<<<<< HEAD
describe KLTime do 
  before do 
    @date = Time.mktime(2010,6,8)
  end
  context ".make_time" do
    it { KLTime.make_time(@date, "18:30").to_s.should eql "Tue Jun 08 18:30:00 +0900 2010"}
  end
  context ".orvertime" do
    it { KLTime.orvertime(@date, "18:30",30).to_s.should eql "Tue Jun 08 19:00:00 +0900 2010"}
  end
end


=======
>>>>>>> c9da87aa3daa7a101455db925941918a183b87e8
describe WorkContent do 
  context ".new" do 
    before do 
      @t1 = WorkRecord.new(['t'],Date.new)
      @t2 = WorkRecord.new(['t'],Date.new)
      @records = [@t1, WorkRecord.new([],Date.new), @t2] 
      @target = WorkContent.new(%w[taskID todoName type detail],@records)
    end
    it "内容が保持されていること" do 
      @target.task_id.should eql 'taskID'
      @target.todo_name.should eql 'todoName'
      @target.type.should eql 'type'
      @target.detail.should eql 'detail'
    end
    it "実績のないレコードは削除されていること" do 
      @target.records.should have(2).record
      @target.records.first.should eql @t1
      @target.records.last.should eql @t2
    end
    it "種類の変換が行われていること" do 
      WorkContent::TYPE_TABLE.each do |k,v|
        target = WorkContent.new(['taskID','todoName',k,'detail' ],@records)
        target.type_code.should eql v
      end
    end
  end
end
