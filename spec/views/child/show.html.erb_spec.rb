require 'spec_helper'

class Schema;
end

describe "children/show.html.erb" do

  describe "displaying a child's details"  do

    before :each do
      @form_section = FormSection.new :unique_id => "section_name", :enabled => "true"
      @child = Child.create(:name => "fakechild", :age => "27", :gender => "male", :date_of_separation => "1-2 weeks ago", :unique_identifier => "georgelon12345", :created_by => 'jsmith', :created_at => "July 19 2010 13:05:32UTC", :photo => uploadable_photo_jeff)
      @child.stub!(:has_one_interviewer?).and_return(true)

      assigns[:form_sections] = [@form_section]
      assigns[:child] = @child
      assigns[:user] = User.new
      assigns[:duplicates] = Array.new
    end

    it "displays the child's photo and thumbnails" do
      assigns[:aside] = 'picture'

      render :layout => 'application'

      response.should have_tag(".content-aside .profile-image .image") do
        with_tag("a[href=?]", child_resized_photo_path(@child, @child.primary_photo_id, 640))
        with_tag("img[src=?]", child_resized_photo_path(@child, @child.primary_photo_id, 328))
      end

      response.should have_tag(".content-aside .thumbnails") do
        with_tag("img[alt=?][src=?]", @child['name'], child_thumbnail_path(@child, @child.primary_photo_id))
      end

    end

    it "renders all fields found on the FormSection" do
      @form_section.add_field Field.new_text_field("age", "Age")
      @form_section.add_field Field.new_radio_button("gender", ["male", "female"], "Gender")
      @form_section.add_field Field.new_select_box("date_of_separation", ["1-2 weeks ago", "More than"], "Date of separation")

      render

      response.should have_tag(".section_name") do
        with_tag(".profile-section-label", /Age/)
        with_tag(".profile-section-label", /Gender/)
        with_tag(".profile-section-label", /Date of separation/)
      end

      response.should have_tag(".section_name .profile-section-value") do
        with_tag(".profile-section-value", "27")
        with_tag(".profile-section-value", "male")
        with_tag(".profile-section-value", "1-2 weeks ago")
      end
    end

    it "does not render fields found on a disabled FormSection" do
      @form_section['enabled'] = false

      render

      response.should_not have_tag("dl.section_name dt")
    end

    describe "interviewer details" do
      it "should show registered by details and no link to change log if child has not been updated" do
        render

        response.should have_tag("#interviewer_details", /Registered by: jsmith/)
        response.should_not have_tag("#interviewer_details", /and others/)
        response.should_not have_tag("#interviewer_details", /Last updated:/)
      end

      it "should show link to change log if child has been updated by multiple people" do
        child = Child.new(:age => "27", :unique_identifier => "georgelon12345", :_id => "id12345", :created_by => 'jsmith', :created_at => "July 19 2010 13:05:32UTC", :last_updated_by => "jdoe", :last_updated_at => "July 20 2010 14:15:59UTC")
        child.stub!(:has_one_interviewer?).and_return(false)

        assigns[:child] = child

        render

        response.should have_tag("#interviewer_details", /Registered by: jsmith/)
        response.should have_tag("#interviewer_details", /and others/)
        response.should have_tag("#interviewer_details", /Last updated:/)
      end

      it "should not show link to change log if child was registered by and updated again by only the same person" do
        render

        response.should have_tag("#interviewer_details", /Registered by: jsmith/)
        response.should_not have_tag("#interviewer_details", /and others/)
      end

   		it "should always show the posted at details when the record has been posted from a mobile client" do
					child = Child.new(:posted_at=> "2007-01-01 14:04UTC", :posted_from=>"Mobile", :unique_id=>"bob",
                            :_id=>"123123", :created_by => 'jsmith', :created_at => "July 19 2010 13:05:32UTC")
      	  child.stub!(:has_one_interviewer?).and_return(true)

          user = User.new 'time_zone' => TZInfo::Timezone.get("US/Samoa")
        
    	  	assigns[:child] = child
          assigns[:user] = user

       		render

        	response.should have_selector("#interviewer_details") do |fields|
          		fields[0].should contain("Posted from the mobile client at: 01 January 2007 at 03:04 (SST)")
        	end 
			end

			it "should not show the posted at details when the record has not been posted from mobile client" do
       		render

        	response.should have_selector("#interviewer_details") do |fields|
          		fields[0].should_not contain("Posted from the mobile client")
        	end 
			end
		end

  end

end
