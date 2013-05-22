require 'spec_helper'

describe DownloadsController do
  before do
    Rails.application.routes.draw do
      resources :downloads
    end
  end

  describe "routing" do
    it "should route" do
      assert_recognizes( {:controller=>"downloads", :action=>"show", "id"=>"test1"}, "/downloads/test1?filename=my%20dog.jpg" )
    end
  end

  describe "with a file" do
    before do
      @user = User.create!(email: 'email@example.com', password: 'password')
      @obj = ActiveFedora::Base.new
      @obj = ModsAsset.new
      @obj.label = "world.png"
      @obj.add_file_datastream('fizz', :dsid=>'buzz', :mimeType => 'image/png')
      @obj.add_file_datastream('whip', :dsid=>'whip', :mimeType => 'audio/mp3')
      @obj.add_file_datastream('foobarfoobarfoobar', :dsid=>'content', :mimeType => 'image/png')
      @obj.add_file_datastream("It's a stream", :dsid=>'descMetadata', :mimeType => 'text/plain')
      @obj.read_users = [@user.user_key]
      @obj.save!
    end
    after do
      @obj.destroy
    end 
    describe "when logged in as reader" do
      before do
        sign_in @user
        User.any_instance.stub(:groups).and_return([])
      end
      describe "show" do
        it "should default to returning default download configured by object" do
          ModsAsset.stub(:default_content_ds).and_return('buzz')
          get "show", :id => @obj.pid
          response.should be_success
          response.headers['Content-Type'].should == "image/png"
          response.headers["Content-Disposition"].should == "inline; filename=\"world.png\""
          response.body.should == 'fizz'
        end
        it "should default to returning default download configured by controller" do
          DownloadsController.default_content_dsid.should == "content"
          get "show", :id => @obj.pid
          response.should be_success
          response.headers['Content-Type'].should == "image/png"
          response.headers["Content-Disposition"].should == "inline; filename=\"world.png\""
          response.body.should == 'foobarfoobarfoobar'
        end
        it "should return requested datastreams" do
          get "show", :id => @obj.pid, :datastream_id => "descMetadata"
          response.should be_success
          response.headers['Content-Type'].should == "text/plain"
          response.headers["Content-Disposition"].should == "inline; filename=\"world.png\""
          response.body.should == "It's a stream"
        end
        it "should support setting disposition to inline" do
          get "show", :id => @obj.pid, :disposition => "inline"
          response.should be_success
          response.headers['Content-Type'].should == "image/png"
          response.headers["Content-Disposition"].should == "inline; filename=\"world.png\""
          response.body.should == 'foobarfoobarfoobar'
        end
        it "should allow you to specify filename for download" do
          get "show", :id => @obj.pid, "filename" => "my%20dog.png"
          response.should be_success
          response.headers['Content-Type'].should == "image/png"
          response.headers["Content-Disposition"].should == "inline; filename=\"my%20dog.png\""
          response.body.should == 'foobarfoobarfoobar'
        end
        it "should default to return the correct mime type for an mp3" do
          ModsAsset.stub(:default_content_ds).and_return('whip')
          get "show", :id => @obj.pid
          response.should be_success
          response.headers['Content-Type'].should == "audio/mp3"
          response.headers["Content-Disposition"].should == "inline; filename=\"world.png\""
          response.body.should == 'whip'
        end
        it "should return the correct mime type for mp3 content" do
          DownloadsController.default_content_dsid.should == "content"
          f = ModsAsset.new
          f.read_users = [@user.user_key]
	  f.apply_depositor_metadata('archivist1@example.com')
          f.label='horse mp3'
          f.add_file_datastream(File.new(File.expand_path("../../fixtures", __FILE__) + '/horse.mp3'), :dsid=>'content', :mimeType => 'audio/mp3')
          f.save!
          file = File.open(File.expand_path("../../fixtures", __FILE__) + '/horse.mp3', "rb")
          expected_content = file.read
          controller.should_receive(:send_file_headers!).with({ :disposition => 'inline',  :type => 'audio/mp3', :filename => 'horse mp3' })
          get "show", :id => f.pid
          response.body.should == expected_content
          response.header["Content-Type"].should == "audio/mp3"
          response.should be_success
        end
      end
    end

    describe "when not logged in as reader" do
      describe "show" do
        before do
          sign_in User.create!(email: 'email2@example.com', password: 'password')
        end
        it "should deny access" do
          lambda { get "show", :id =>@obj.pid }.should raise_error Hydra::AccessDenied
        end
      end
    end
  end
end
