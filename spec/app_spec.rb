require_relative './spec_helper'

describe "Dharma API" do

  before :all do
    @auth = '?api_key=123'
  end

  describe "Authentication" do
    it "should return a 401 status with no results for an invalid API key" do
      get '/talks' do
        last_response.status.should be 401
        json = JSON.parse(last_response.body)
        json['results'].count.should <= 1
      end
    end
  end

  describe "Homepage" do
    it "should load the home page" do
      get '/'
      last_response.should be_ok
    end
  end

  describe '/talk/:id' do
    it "should return a talk with its speaker" do
    	get '/talk/1' + @auth
    	json = JSON.parse(last_response.body)['results'][0]
    	json['title'].should eq 'Advise For Taking Awareness Home'
    	json['description'].start_with?('Insight Meditation Society').should eq true
    	json['duration'].should eq 1433
    	json['event'].should eq "Dhamma Everywhere: Awareness with Wisdom Retreat"
    	json['speaker']['name'].should eq "Sayadaw U Tejaniya"
    	json['speaker']['picture'].should eq 'http://media.dharmaseed.org/uploads/photos/thumb_tejaniya.jpg'
    end
  end

  describe '/speaker/:id' do
    it "should return a speaker with talks" do
    	get '/speaker/2' + @auth
    	json = JSON.parse(last_response.body)['results'][0]
    	json['name'].should eq "Thanissara" 
    	json['bio'].start_with?('Thanissara, a practitioner since 1975, was a T').should eq true
    	json['picture'].should eq 'http://media.dharmaseed.org/uploads/photos/thumb_Thanissara_ok.jpg'
    	json['talks'].count eq 1
    end
  end

  describe "/talks" do
    it "should return a page of talks when called without args" do
      get '/talks' + @auth
      json = JSON.parse(last_response.body)
      metta = json['metta']
      metta['total'].should eq 5
      results = json['results']
      results.count.should eq 5
    end

    it "should find the talk with 'mountain' in it" do
      get "/talks#{@auth}&search=mountain"
      json = JSON.parse(last_response.body)['results'][0]
      json['permalink'].should eq "http://dharmaseed.org/teacher/178/talk/16074/20120510-Thanissara-DG-3_9_68_icon_of_the_heart.mp3"
    end
  end

  describe "/speakers" do
    it "should return a page of speakers when called without args" do
      get '/speakers' + @auth
      json = JSON.parse(last_response.body)
      metta = json['metta']
      metta['total'].should eq 3
      results = json['results']
      results.count.should eq 3
    end
    it "should find the speaker with 'Burma' in their bio" do
      get "/speakers#{@auth}&search=Burma"
      json = JSON.parse(last_response.body)['results'][0]      
      json['name'].should eq "Sayadaw U Tejaniya"
    end
  end

  #TODO spec pagination, ordering and 404s

  describe "API key manager" do

    include Mail::Matchers
    
    describe "/request_api_key" do
      before :all do
        Mail::TestMailer.deliveries.clear
        @email = "sample@somewhere.com"
        get "/request_api_key?email=" + @email
      end

      it "should send an email with an API key in it" do
        last_response.status.should be 200
        @api_key = Key.find_by_email(@email).api_key
        @api_key.empty?.should_not eq true
        should have_sent_email.to(@email)
        should have_sent_email.matching_body(/#{@api_key}/)
      end
    end

  end

end